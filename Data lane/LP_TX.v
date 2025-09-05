module LP_TX(
        input wire clk,
        input wire rst,
        input wire n, p,
        output reg on, op
    );

    always @(posedge rst or posedge clk) 
    begin
        if (rst)
        begin
            on <= 0;
            op <= 0;
        end
        else
        begin
            on <= n;
            op <= p ;
        end
    end

endmodule
