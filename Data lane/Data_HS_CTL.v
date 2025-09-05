`timescale 1ns / 1ps

module Data_HS_CTL(
    
    input wire          clk, rst,            
                        Serial_End,
                        hs_en,                  //  Enables and disables high speed mode
                        TxDataTransferEnHS,
                        TxWordValidHS,
                        time_done,              // Timer is done counting signal to allow us to go to sync sequence state

    input wire [31:0]   TxDataHS,

    output reg          TxRdHS,
                        Serial_En,
                        Trail,
                        Trail_sel,
                        Sync_dn,
                        time_reset,
                        Serial_Valid,
                        timer_enable,
                        valid_done,

    output reg [7:0]    HS_prll_data                

    );
    reg [3:0] current_state, next_state;
    
    localparam          HS_OFF      = 0,  // bagarrab gray code
                        HS0         = 1,
                        SYNC_SEC    = 3,
                        HS_DATA     = 2,
                        HS_TRAIL    = 6;

    always @(posedge clk or posedge rst) 
    begin
        if (rst) 
        begin
            current_state       <= HS_OFF;
            TxRdHS              <= 0;
            Serial_En           <= 0;
            Trail               <= 0;
            Trail_sel           <= 0;
            Sync_dn             <= 0;
            Serial_Valid        <= 0;
            timer_enable        <= 0;
            valid_done          <= 0;
            HS_prll_data        <= 0;
        end
        else
            current_state <= next_state;
    end


    always @(*) 
    begin
        case (current_state)
            HS_OFF:
            begin
                if (hs_en) 
                    next_state = HS0;    
                else
                    next_state = HS_OFF;
            end
            HS0:
            begin
                if (TxDataTransferEnHS && time_done) 
                    next_state = SYNC_SEC;    
                else
                    next_state = HS0;                
            end
            SYNC_SEC:
            begin
                if (!Serial_End) 
                    next_state = HS_DATA;    
                else
                    next_state = SYNC_SEC;
                
            end
            HS_DATA:
            begin
                if (!TxWordValidHS) 
                    next_state = HS_TRAIL;    
                else
                    next_state = HS_DATA;
            end
            HS_TRAIL: 
            begin
                if (hs_en) 
                    next_state = HS_OFF;    
                else
                    next_state = HS_TRAIL;
            end
            default: 
            begin 
                next_state = HS_OFF;  
            end
        endcase
    end


    always @(*) 
    begin
        case (current_state)
            HS_OFF:
            begin
                Serial_En = 1'b0;
                HS_prll_data = 1'b0;
                Trail_sel = 1'b0;
                TxRdHS = 1'b0;
                time_reset = 1'b0;
                timer_enable = 1'b0;
                Serial_Valid = 1'b0;
            end
            HS0:
            begin
                Serial_En = 0;
                HS_prll_data = 0;
                Trail_sel = 1;
                TxRdHS = 0;
                time_reset = 11;
                timer_enable = 1;
                Serial_Valid = 0;                
            end
            SYNC_SEC:
            begin
                Serial_En = 1;
                Serial_Valid = 1;
                Trail_sel = 0;
                TxRdHS = 0;
                time_reset = 0;
                timer_enable = 0;
                HS_prll_data = 29;
            end
            HS_DATA:
            begin
                Serial_En = 1;
                Trail_sel = 0;
                TxRdHS = 1;
                Serial_Valid = 1;
                time_reset = 0;
                timer_enable = 0;
                if(TxWordValidHS) 
                    HS_prll_data = TxDataHS;
                else 
                begin
                    HS_prll_data = 0;
					Serial_Valid = 0;
                    valid_done = 1;
                end
            end
            HS_TRAIL: 
            begin
                Serial_En = 0;
                HS_prll_data = 0;
                Trail_sel = 1;
                Serial_Valid = 0;
                TxRdHS = 1'b0;
                time_reset = 6;
                valid_done = 1;
                timer_enable = 1;
            end
            default: 
            begin 
                Serial_En = 0;
                HS_prll_data = 0;
                Serial_Valid = 0;
                Trail_sel = 0;
                TxRdHS = 0;
                time_reset = 0;
                timer_enable = 0;  
            end
        endcase            
    end


    always @(posedge clk or negedge rst)
    begin
        if(!rst) 
            Trail <= 0;
        else if(current_state == HS_OFF) 
            Trail <= 0;
        else if(current_state == HS_DATA && TxWordValidHS) 
            Trail <= !TxDataHS[0];
    end
endmodule
