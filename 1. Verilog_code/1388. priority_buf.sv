module priority_buf #(parameter DW=16) (
    input clk, rst_n,
    input [1:0] pri_level,
    input wr_en, rd_en,
    input [DW-1:0] din,
    output reg [DW-1:0] dout
);
    reg [DW-1:0] mem[0:3];
    reg [1:0] rd_ptr = 0;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            mem[0] <= 0; mem[1] <= 0;
            mem[2] <= 0; mem[3] <= 0;
        end
        else if(wr_en) 
            mem[pri_level] <= din;
    end
    
    always @(posedge clk) begin
        if(rd_en) begin
            dout <= mem[rd_ptr];
            rd_ptr <= (rd_ptr == 3) ? 0 : rd_ptr + 1;
        end
    end
endmodule
