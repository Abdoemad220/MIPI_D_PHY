module out_logic(
        input wire clk,
        input wire rst,
        input wire lpn, lpp, hs, s
        output reg p, n
    );

    always @(posedge rst or posedge clk) 
    begin
        if (rst)
        begin
            p <= 0;
            n <= 0;
        end
        else
        begin
            if (s) 
            begin
                p <= hs;
                n <= !hs;
            end 
            else
            begin
                p <= lpp;
                n <= lpn;
            end
        end
    end

endmodule
