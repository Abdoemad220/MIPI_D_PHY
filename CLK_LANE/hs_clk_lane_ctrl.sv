module hs_clk_ctrl(
    input logic clk, rst, //Main system clock + Asynchronous active-high reset
    input logic hs_enable, //Global high-speed mode enable
    input logic time_pass, //handshake signal from a timer (asserted when the requested timing period has expired)
    input logic hs_req, //Request from the data path to start HS transmission.

    output logic hs_clk, //High-speed clock output
    output logic hs_active, //Acknowledge signal to the data path that HS transmission is active

    //interface with timer 
    output logic timer_enable, //Enable signal to the timer module
    output logic [5:0] timer_reload //Reload signal to the timer module

);
//Assuming TCLK = 100MHz
//ZERO_CLK ≈ 300 ns -> how long HS clk must be 0 before toggling
//RX_SETUP ≈ 38 ns -> time between HS clk going high and data starts toggling
//POST_DATA ≈ 60 ns -> time between last data toggle and HS clk going low
//STOP_CLK ≈ 60 ns -> keeping HS clk low after stopping, ensuring proper returning to LP mode

localparam  ZERO_CLK = 27,
            RX_SETUP = 4,
            POST_DATA = 6,
            STOP_CLK = 6;

logic hs_clk_enable; //Internal signal to enable/disable HS clock 

typedef enum logic [2:0] {
    IDLE_OFF = 3'b000,
    HS_START = 3'b001, 
    CLK_PREPARE = 3'b011,
    HS_ACTIVE = 3'b010,  
    PRE_HS_STOP = 3'b110, 
    HS_STOP = 3'b111
} state_t;
state_t current_state, next_state;

always @(posedge clk or posedge rst) begin
    if (rst) 
        current_state <= IDLE_OFF;
    else
        current_state <= next_state;
        
end

always @(*) begin
    case (current_state)
        IDLE_OFF: begin
            if (hs_enable && hs_req) 
                next_state = HS_START;
            else 
                next_state = IDLE_OFF;
        end

        HS_START: begin
            if(time_pass)
                next_state = CLK_PREPARE;
            else 
                next_state = HS_START;
        end

        CLK_PREPARE: begin
            if(!hs_enable || !hs_req) //abort condition
                next_state = IDLE_OFF;
            else if(time_pass)
                next_state = HS_ACTIVE;
            else
                next_state = CLK_PREPARE;
        end

        HS_ACTIVE: begin
            if (!hs_req) 
                next_state = PRE_HS_STOP;
            else 
                next_state = HS_ACTIVE;
        end

        PRE_HS_STOP: begin
            if (time_pass)
                next_state = HS_STOP;
            else
                next_state = PRE_HS_STOP;
        end

        HS_STOP: begin
            if (time_pass)
                next_state = IDLE_OFF;
            else 
                next_state = HS_STOP;
        end
        
        default: 
            next_state = IDLE_OFF;
endcase
end

always @(*) begin
    case(current_state)
        IDLE_OFF: begin
            hs_clk_enable = 1'b0;
            hs_active = 1'b0;
            timer_enable = 1'b0;
            timer_reload = 1'b0;
        end
        HS_START: begin
            hs_clk_enable = 1'b0;
            hs_active = 1'b0;
            timer_enable =  1'b1;
            timer_reload =  ZERO_CLK;
        end

        CLK_PREPARE: begin
            hs_clk_enable = 1'b1; //geenrate HS clock to setup Rx for upcoming data
            hs_active = 1'b0;
            timer_enable = 1'b1;
            timer_reload = RX_SETUP; //Reload timer with RX_SETUP
        end
        HS_ACTIVE: begin
            hs_clk_enable = 1'b1; //Stilltoggling 
            hs_active = 1'b1;
            timer_enable = 1'b0;
            timer_reload = 1'b0; 
        end         
        PRE_HS_STOP: begin
            hs_clk_enable = 1'b1; 
            hs_active = 1'b0;
            timer_enable = 1'b1;
            timer_reload = POST_DATA; //Reload timer with POST_DATA
        end
        HS_STOP: begin
            hs_clk_enable = 1'b0; 
            hs_active = 1'b0;
            timer_enable = 1'b1;
            timer_reload = STOP_CLK; //Reload timer with STOP_CLK
        end
        default: begin
            hs_clk_enable = 1'b0;
            hs_active = 1'b0;
            timer_enable = 1'b0;
            timer_reload = 1'b0;
        end
    endcase
end




always_comb begin
        hs_clk = (hs_clk_enable ) ? clk : 1'b0;
end







//assign hs_clk = (hs_clk_enable ) ? clk : 1'b0;
/*
logic no_glitch_reg;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        no_glitch_reg <= 1'b0;
    end else begin
        no_glitch_reg <= (current_state == PRE_HS_STOP && time_pass);
    end
end

assign hs_clk = (hs_clk_enable && !no_glitch_reg) ? clk : 1'b0;
*/
//Clock Generator:
//logic no_glitch;
//assign no_glitch = (current_state == PRE_HS_STOP && time_pass)? 1'b1 : 1'b0; 
//assign hs_clk = (hs_clk_enable ^ no_glitch ) ? clk : 1'b0;

    



endmodule