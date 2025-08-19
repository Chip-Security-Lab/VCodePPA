//SystemVerilog
module decoder_sync #(ADDR_WIDTH=4, DATA_WIDTH=8) (
    input clk, rst_n,
    input [ADDR_WIDTH-1:0] addr,
    output reg [DATA_WIDTH-1:0] data
);

wire [1:0] addr_lsb = addr[1:0];
wire addr_eq_0 = (addr[3:0] == 4'h0);
wire addr_eq_4 = (addr[3:0] == 4'h4);
wire [1:0] sel = {addr_eq_4, addr_eq_0};

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
        data <= 0;
    else begin
        case(sel)
            2'b01: data <= 8'h01;  // addr == 0
            2'b10: data <= 8'h02;  // addr == 4
            default: data <= 8'h00;
        endcase
    end
end

endmodule