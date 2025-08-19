//SystemVerilog
module sync_width_conv #(parameter IN_W=8, OUT_W=16, DEPTH=4) (
    input clk, rst_n,
    input [IN_W-1:0] din,
    input wr_en, rd_en,
    output full, empty,
    output reg [OUT_W-1:0] dout
);
    localparam CNT_W = $clog2(DEPTH);
    reg [IN_W-1:0] buffer[0:DEPTH-1];
    reg [CNT_W:0] wr_ptr = 0, rd_ptr = 0;
    
    wire [CNT_W-1:0] wr_addr = wr_ptr[CNT_W-1:0];
    wire [CNT_W-1:0] rd_addr = rd_ptr[CNT_W-1:0];
    wire [CNT_W-1:0] rd_addr_plus1 = rd_addr + 1'b1;
    wire [CNT_W:0] ptr_diff = wr_ptr - rd_ptr;
    
    assign full = ptr_diff >= DEPTH;
    assign empty = (ptr_diff == 0);
    
    wire wr_valid = wr_en && !full;
    wire rd_valid = rd_en && !empty;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            dout <= 0;
        end
        else begin
            if (wr_valid) begin
                buffer[wr_addr] <= din;
                wr_ptr <= wr_ptr + 1'b1;
            end
            
            if (rd_valid) begin
                dout <= {buffer[rd_addr_plus1], buffer[rd_addr]};
                rd_ptr <= rd_ptr + 2'b10;
            end
        end
    end
endmodule