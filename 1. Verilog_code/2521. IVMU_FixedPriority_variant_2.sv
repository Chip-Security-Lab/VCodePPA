//SystemVerilog
module IVMU_FixedPriority #(parameter WIDTH=8, ADDR=4) (
    input clk, rst_n,
    input [WIDTH-1:0] int_req,
    output reg [ADDR-1:0] vec_addr
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset vec_addr to 0
        vec_addr <= {ADDR{1'b0}};
    end else begin
        // Implement fixed priority logic using casez statement
        // Priority order: bit 7 > bit 6 > bit 5
        // Evaluate relevant bits for priority
        casez (int_req[7:5])
            3'b1zz: begin // int_req[7] is high
                vec_addr <= 4'h7;
            end
            3'b01z: begin // int_req[7] is low, int_req[6] is high
                vec_addr <= 4'h6;
            end
            3'b001: begin // int_req[7] and int_req[6] are low, int_req[5] is high
                vec_addr <= 4'h5;
            end
            default: begin // None of the prioritized bits are high
                vec_addr <= {ADDR{1'b0}};
            end
        endcase
    end
end

endmodule