//SystemVerilog
module priority_buf #(parameter DW=16) (
    input clk, rst_n,
    input [1:0] pri_level,
    input wr_en, rd_en,
    input [DW-1:0] din,
    output reg [DW-1:0] dout
);
    // Memory array and pointers
    reg [DW-1:0] mem[0:3];
    reg [1:0] rd_ptr, next_rd_ptr;
    
    // Pre-compute next read pointer to reduce critical path
    always @(*) begin
        next_rd_ptr = rd_ptr + 2'b01;
        if(rd_ptr == 2'b11) begin
            next_rd_ptr = 2'b00;
        end
    end
    
    // Combined reset and operational logic for read pointer
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            rd_ptr <= 2'b00;
        end
        else if(rd_en) begin
            rd_ptr <= next_rd_ptr;
        end
    end
    
    // Write logic
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            mem[0] <= {DW{1'b0}};
            mem[1] <= {DW{1'b0}};
            mem[2] <= {DW{1'b0}};
            mem[3] <= {DW{1'b0}};
        end
        else if(wr_en) begin
            mem[pri_level] <= din;
        end
    end
    
    // Read data logic
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            dout <= {DW{1'b0}};
        end
        else if(rd_en) begin
            dout <= mem[rd_ptr];
        end
    end
endmodule