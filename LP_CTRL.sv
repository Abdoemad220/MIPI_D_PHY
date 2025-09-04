module LP_CTRL_CLK_Lane #(
        parameter TIME_WAIT_WIDTH = 32
    )(
        input  TxClkEsc,
        input  rst_n,
        input  ForceTxStopmode,
        input  Enable,
        input  TxUlpsExit,
        input  TxRequestHS,
        input  time_flag,
        input  TxUlpsClk,

        output reg  timer_enable,
        output reg  ULP_CG_EN,
        output reg  Stopstate,
        output reg  UlpsActiveNot,
        output reg [1:0] LP_MODE_SEQ,
        output reg  HS_EN,
        output reg  [TIME_WAIT_WIDTH-1:0] time_wait
    );


    parameter T_LPX = 2 ;
    parameter T_prepare = 1 ;
    parameter T_POST  = 2;
    parameter T_TRAIL = 2;
    parameter T_Wakeup = 20000 ;

    typedef enum bit [3:0] {
                turned_off,
                stop,
                HS_RQST,
                Bridge,
                SEQ_HS0,
                Trail,
                ULPS_RQST,
                ULPS,
                ULPS_EXIT
            } state_t;
    state_t current_state,next_state;


    ///////////////////////////CS///////////////////
    always @(posedge TxClkEsc or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= turned_off;
        end
        else begin
            current_state <= next_state;
        end
    end




    //////////////////next state////////////////////
    always @(*) begin
        case (current_state)
            turned_off: begin
                if (Enable && ForceTxStopmode) begin
                    next_state = stop;
                end
                else begin
                    next_state = turned_off;
                end
            end
            stop: begin
                if (TxRequestHS && !ForceTxStopmode) begin
                    next_state = HS_RQST;
                end
                else if (TxUlpsClk && !TxRequestHS && !ForceTxStopmode) begin
                    next_state = ULPS_RQST;
                end
                else begin
                    next_state = stop;
                end
            end
            HS_RQST: begin
                if (time_flag) begin
                    next_state = Bridge;
                end
                else begin
                    next_state = HS_RQST;
                end
            end
            Bridge: begin
                if (time_flag) begin
                    next_state = SEQ_HS0;
                end
                else begin
                    next_state = Bridge;
                end
            end
            SEQ_HS0: begin
                if (!TxRequestHS) begin
                    next_state = Trail;
                end
                else begin
                    next_state = SEQ_HS0;
                end
            end
            Trail: begin
                if (time_flag) begin
                    next_state = stop;
                end
                else begin
                    next_state = Trail;
                end
            end
            ULPS_RQST: begin
                if (time_flag && TxUlpsClk) begin
                    next_state = ULPS;
                end
                else begin
                    next_state = ULPS_RQST;
                end
            end
            ULPS: begin
                if (TxUlpsExit) begin
                    next_state = ULPS_EXIT;
                end
                else begin
                    next_state = ULPS;
                end
            end
            ULPS_EXIT: begin
                if (time_flag) begin
                    next_state = stop;
                end
                else begin
                    next_state = ULPS_EXIT;
                end
            end
            default: begin
                next_state = turned_off;
            end
        endcase
    end

    //////////////////output logic//////////////////
    always @(*) begin
        timer_enable = 1'b0;
        ULP_CG_EN = 1'b0;
        Stopstate = 1'b0;
        UlpsActiveNot = 1'b1;
        LP_MODE_SEQ = 2'b00;
        HS_EN = 1'b0;
        time_wait = {TIME_WAIT_WIDTH{1'b0}};

        case (current_state)
            turned_off: begin
                timer_enable = 1'b0;
                ULP_CG_EN = 1'b0;
                Stopstate = 1'b0;
                UlpsActiveNot = 1'b1;
                LP_MODE_SEQ = 2'b00;
                HS_EN = 1'b0;
                time_wait = {TIME_WAIT_WIDTH{1'b0}};
            end
            stop: begin
                LP_MODE_SEQ = 2'b11;
                Stopstate = 1'b1;
            end
            HS_RQST: begin
                LP_MODE_SEQ = 2'b01;
                timer_enable = 1'b1;
                time_wait = T_LPX;
                if(time_flag) begin
                    timer_enable = 1'b0;
                end
            end
            Bridge: begin
                LP_MODE_SEQ=2'b00;
                timer_enable=1'b1;
                time_wait=T_prepare;
                if(time_flag) begin
                    timer_enable = 1'b0;
                end
            end
            SEQ_HS0: begin
                HS_EN=1;
            end
            Trail: begin
                HS_EN=1;
                timer_enable=1;
                time_wait=T_POST+T_TRAIL;
                if(time_flag) begin
                    timer_enable = 1'b0;
                end
            end
            ULPS_RQST: begin
                LP_MODE_SEQ=2'b10;
                timer_enable=1;
                time_wait=T_LPX;
                if(time_flag) begin
                    timer_enable = 1'b0;
                end
            end
            ULPS: begin
                LP_MODE_SEQ=2'b00;
                UlpsActiveNot=1'b0;
                ULP_CG_EN=1'b1;
                timer_enable=1'b1;
                time_wait=T_LPX;
                if(time_flag) begin
                    timer_enable = 1'b0;
                end
            end
            ULPS_EXIT: begin
                LP_MODE_SEQ=2'b10;
                UlpsActiveNot=1'b1;
                timer_enable=1'b1;
                time_wait=T_Wakeup;
                if(time_flag) begin
                    timer_enable = 1'b0;
                end
            end

        endcase
    end

endmodule




