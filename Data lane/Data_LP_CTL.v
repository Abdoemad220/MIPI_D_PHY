`timescale 1ns / 1ps

module Data_LP_CTL(
    input  wire         clk, rst,
                        Enable, 
                        ForceTxStopmode, 
                        TxRqEsc, 
                        TxRdHS,
                        TxUlpsEsc, 
                        TxUlpsExit,
                        TxRqHS, 
                        TxValidEsc,  
                        hs_finished, 
                        hs_en,  
                        lp_mode_eq,
                        timer_passed,
                        TxLpdtEsc,

    input  wire [3:0]   TxTriggerEsc, 

    input  wire [7:0]   TxDataEsc,

    output reg          TxRdEsc,
                        StopState,
                        Timer_En,
                        UIpsActiveNot,
                        HS_EN,
                        LP_MODE_SEQ,
                        LP_TRAIL_FLAG,
                        Clk_Div_En,
                        ULP_CG_EN,
                        ESC_SER_ENC_EN,

    output reg [7:0]    TxData,
    output reg [31:0]   time_wait   
); 

reg [3:0] current_state, next_state, counter;


localparam  TURNED_OFF          = 0,
            STOP                = 1,
            HS_RQST             = 2,
            BRIDGE              = 3,
            HS_TRANSMISSION     = 4,
            LP_RQST             = 5,
            YIELD               = 6,
            ESC_RQST            = 7,
            ESC_GO              = 8,
            ESC_CMD             = 9,
            LPDT                = 10,
            MARK1               = 11,
            TRIGGER             = 12,
            ULPS                = 13;

// localparam  TURNED_OFF          = 0,     law fee wa2t
//             STOP                = 1,     3ayz agarrab 
//             HS_RQST             = 3,     gray code
//             BRIDGE              = 2,     hena kaman
//             HS_TRANSMISSION     = 6,
//             LP_RQST             = 7,
//             YIELD               = 5,
//             ESC_RQST            = 4,
//             ESC_GO              = 12,
//             ESC_CMD             = 13,
//             LPDT                = 15,
//             MARK1               = 14,
//             TRIGGER             = 10,
//             ULPS                = 11;


always @(posedge clk or posedge rst) 
begin
    if (rst) 
    begin
        current_state       <= TURNED_OFF;
        TxRdEsc             <= 0;
        StopState           <= 0;
        Timer_En            <= 0;
        UIpsActiveNot       <= 0;
        HS_EN               <= 0;
        LP_MODE_SEQ         <= 0;
        LP_TRAIL_FLAG       <= 0;
        time_wait           <= 0;
    end
    else    
        current_state <= next_state;
end

always @(posedge clk or posedge rst) 
begin
    if (rst) 
        counter <= 0;
    else    
        counter <= counter + 1;
end

always @(*) 
begin
    case (current_state)
    TURNED_OFF:
    begin
        if (ForceTxStopmode && Enable) 
            next_state = STOP;
        else
            next_state = TURNED_OFF;
    end 
    STOP:
    begin
        if (TxRqHS && !TxRqEsc && !ForceTxStopmode && TxRdHS) 
            next_state = HS_RQST;
        else if (!TxRqHS && TxRqEsc && !ForceTxStopmode) 
            next_state = LP_RQST;
        else
            next_state = STOP;
    end
    HS_RQST:
    begin
        if (timer_passed) 
            next_state = BRIDGE;
        else
            next_state = HS_RQST;
    end
    BRIDGE:
    begin
        if (timer_passed) 
            next_state = HS_TRANSMISSION;
        else
            next_state = BRIDGE;
    end
    HS_TRANSMISSION:
    begin
        if (hs_finished) 
            next_state = HS_TRANSMISSION;
        else
            next_state = STOP;
    end
    LP_RQST:
    begin
        if (timer_passed) 
            next_state = YIELD;
        else
            next_state = LP_RQST;
    end
    YIELD:
    begin
        if (timer_passed) 
            next_state = YIELD;
        else
            next_state = ESC_RQST;
    end
    ESC_RQST:
    begin
        if (timer_passed) 
            next_state = ESC_RQST;
        else
            next_state = ESC_GO;
    end
    ESC_GO:
    begin
        if (timer_passed) 
            next_state = ESC_GO;
        else
            next_state = ESC_CMD;
    end
    ESC_CMD:
    begin
        if (counter == 15 && TxTriggerEsc && TxRqEsc) 
            next_state = TRIGGER;
        else if (counter == 15 && TxUlpsExit && TxRqEsc)
            next_state = ULPS;
        else if (counter == 15 && TxRqEsc && TxLpdtEsc) 
            next_state = LPDT;
        else
            next_state = ESC_CMD;
    end
    TRIGGER:
    begin
        if (counter == 15) 
            next_state = MARK1;
        else
            next_state = TRIGGER;
    end
    ULPS:
    begin
        if (TxUlpsExit) 
            next_state = MARK1;
        else
            next_state = ULPS;
    end
    LPDT:
    begin
        if (!TxRdEsc && counter == 15) 
            next_state = MARK1;
        else
            next_state = LPDT;
    end
    MARK1:
    begin
        if (timer_passed) 
            next_state = STOP;
        else
            next_state = MARK1;
    end
    default: 
        next_state = TURNED_OFF;
    endcase
end

always @(*) 
begin
    case (current_state)
        TURNED_OFF:
        begin
            TxRdEsc = 0;
            StopState = 0;
            Timer_En = 0;
            UIpsActiveNot = 1;
            HS_EN = 0;
            LP_MODE_SEQ = 0;
            LP_TRAIL_FLAG = 0;
            TxData = 0;
            Clk_Div_En = 0;
            ULP_CG_EN = 0;
            ESC_SER_ENC_EN = 0;
        end
        STOP:
        begin
            StopState = 0;
            LP_MODE_SEQ = 7;
            ESC_SER_ENC_EN = 0;
        end
        HS_RQST:
        begin
            LP_MODE_SEQ         = 5;
            time_wait           = 2;
            ESC_SER_ENC_EN      = 1;
            Timer_En            = 1;
            Clk_Div_En          = 1;
            if (timer_passed)
                Timer_En        = 0;
        end
        BRIDGE:
        begin
            Clk_Div_En          = 1;
            LP_MODE_SEQ         = 3'b100;
            time_wait           = 2;
            ESC_SER_ENC_EN      = 1;
            if (timer_passed)
                Timer_En    = 0;
            else
                Timer_En    = 1;
        end
        HS_TRANSMISSION:
        begin
            Clk_Div_En          = 1;
            HS_EN               = 1;
        end
        LP_RQST:
        begin
            LP_MODE_SEQ         = 3'b100 + (current_state == LP_RQST ? 2 : current_state == ESC_RQST ? 1 : 0);
            time_wait           = 2;
            ESC_SER_ENC_EN      = 1;
            Timer_En        = 1;
            if (timer_passed)
                Timer_En    = 0;
            else
                Timer_En    = 1; 
        end
        YIELD:
        begin
            LP_MODE_SEQ         = 3'b100 + (current_state == LP_RQST ? 2 : current_state == ESC_RQST ? 1 : 0);
            time_wait           = 2;
            ESC_SER_ENC_EN      = 1;
            if (timer_passed)
                Timer_En        = 0;
            else
                Timer_En        = 1;
        end
        ESC_RQST:
        begin
            LP_MODE_SEQ         = 3'b100 + (current_state == LP_RQST ? 2 : current_state == ESC_RQST ? 1 : 0);
            time_wait           = 2;
            ESC_SER_ENC_EN      = 1;
            Timer_En        = 1;
            if (timer_passed)
                Timer_En    = 0;
            else
                Timer_En    = 1;
        end
        ESC_GO:
        begin
            LP_MODE_SEQ         = 3'b100 + (current_state == LP_RQST ? 2 : current_state == ESC_RQST ? 1 : 0); time_wait = 2;
            ESC_SER_ENC_EN      = 1;
            Timer_En        = 1;
            if (timer_passed)
                Timer_En    = 0;
            else
                Timer_En    = 1;
        end
        ESC_CMD:
        begin
            counter = 1'b1;
            if (TxRqEsc && TxTriggerEsc)
                TxData = 8'b0110_0010;
            else if (TxRqEsc && TxLpdtEsc)
                TxData = 8'b1000_0001;
            else if (TxRqEsc && TxUlpsEsc)
                TxData = 8'b0001_1110;
            else
                TxData = 8'b10011111;
            ESC_SER_ENC_EN = 1;
        end
        LPDT:
        begin
            counter = 1'b1;
            TxRdEsc  = (counter == 15) ? 1 : 0;
            ESC_SER_ENC_EN = 1;
            if (TxRqEsc && TxValidEsc)
                TxData = TxDataEsc;
        end
        MARK1:
        begin
            LP_TRAIL_FLAG       = 1;
            ESC_SER_ENC_EN      = 1;
            time_wait           = (TxUlpsEsc) ? 20000 : 2;
            if (timer_passed)
                Timer_En    = 0;
            else
                Timer_En    = 1;
        end
        TRIGGER:
        begin
            counter               = 1'b1;
            ESC_SER_ENC_EN      = 1;
            case (TxTriggerEsc)
                4'b0001: TxData = 8'b01100010;
                4'b0010: TxData = 8'b01011101;
                4'b0100: TxData = 8'b00100001;
                4'b1000: TxData = 8'b10100000;
                default: TxData = 8'hff;
            endcase
        end
        ULPS: 
        begin
            ULP_CG_EN           = 1;
            UIpsActiveNot       = 0;
            LP_MODE_SEQ         = 3'b100;
            ESC_SER_ENC_EN      = 1;
        end
        default: 
        begin
            TxRdEsc = 0;
            StopState = 0;
            Timer_En = 0;
            UIpsActiveNot = 1;
            HS_EN = 0;
            LP_MODE_SEQ = 0;
            LP_TRAIL_FLAG = 0;
            TxData = 0;
            Clk_Div_En = 0;
            ULP_CG_EN = 0;
            ESC_SER_ENC_EN = 0;
        end
    endcase
end

endmodule
