//SystemVerilog
module decoder_time_mux #(parameter TS_BITS=2) (
    input clk, rst_n,
    input [7:0] addr,
    output reg [3:0] decoded
);
    reg [TS_BITS-1:0] time_slot;
    reg [7:0] addr_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            time_slot <= 'b0;
            addr_reg <= 8'b0;
        end else begin
            time_slot <= time_slot + 1'b1;
            addr_reg <= addr;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decoded <= 4'b0000;
        end else begin
            decoded <= addr_reg[time_slot*4 +:4];
        end
    end
endmodule