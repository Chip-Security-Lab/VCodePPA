//SystemVerilog
module shift_add_mult (
    input clk,
    input rst_n,
    input valid,
    output ready,
    input [7:0] mplier,
    input [7:0] mcand,
    output reg [15:0] result,
    output reg result_valid
);

    reg [15:0] accum;
    reg processing;
    
    assign ready = ~processing;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            accum <= 16'b0;
            result <= 16'b0;
            result_valid <= 1'b0;
            processing <= 1'b0;
        end else begin
            if (valid && ready) begin
                processing <= 1'b1;
                accum <= 16'b0;
                if(mplier[0]) accum <= accum + mcand;
                if(mplier[1]) accum <= accum + (mcand << 1);
                if(mplier[2]) accum <= accum + (mcand << 2);
                if(mplier[3]) accum <= accum + (mcand << 3);
                if(mplier[4]) accum <= accum + (mcand << 4);
                if(mplier[5]) accum <= accum + (mcand << 5);
                if(mplier[6]) accum <= accum + (mcand << 6);
                if(mplier[7]) accum <= accum + (mcand << 7);
                result <= accum;
                result_valid <= 1'b1;
            end else if (processing) begin
                processing <= 1'b0;
                result_valid <= 1'b0;
            end
        end
    end
endmodule