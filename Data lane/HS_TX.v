module HS_TX(
        input wire clk,
        input wire rst,
        input wire unstable,
        output reg stable
    );

    always @(posedge rst or posedge clk) 
    begin
        if (rst)
        begin
            stable <= 0;
        end
        else
        begin
            stable <= unstable;   
        end
    end

endmodule
