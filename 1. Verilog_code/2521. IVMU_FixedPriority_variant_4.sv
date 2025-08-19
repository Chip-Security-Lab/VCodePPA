//SystemVerilog
module IVMU_FixedPriority #(parameter WIDTH=8, ADDR=4) (
    input clk, rst_n,
    input [WIDTH-1:0] int_req,
    output reg [ADDR-1:0] vec_addr
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        vec_addr <= 0;
    end else begin
        // Converted casex to if-else if for clarity and potential PPA impact
        if (int_req[7] == 1'b1) begin
            vec_addr <= 4'h7;
        end else if (int_req[6] == 1'b1) begin
            vec_addr <= 4'h6;
        end else if (int_req[5] == 1'b1) begin
            vec_addr <= 4'h5;
        end else begin
            vec_addr <= 0;
        end
    end
end

endmodule