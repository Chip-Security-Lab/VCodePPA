//SystemVerilog
module decoder_sync #(ADDR_WIDTH=4, DATA_WIDTH=8) (
    input clk, rst_n,
    input [ADDR_WIDTH-1:0] addr,
    output reg [DATA_WIDTH-1:0] data,
    output reg valid
);

// Pipeline registers
reg [ADDR_WIDTH-1:0] addr_stage1;
reg [ADDR_WIDTH-1:0] addr_stage2;
reg [DATA_WIDTH-1:0] data_stage1;
reg [DATA_WIDTH-1:0] data_stage2;
reg valid_stage1;
reg valid_stage2;

// Borrow subtractor implementation
reg [3:0] borrow_stage1;
reg [3:0] borrow_stage2;
reg [3:0] diff_stage1;
reg [3:0] diff_stage2;
reg [3:0] addr_sub_stage1;
reg [3:0] addr_sub_stage2;

// Stage 1: Address register and initial borrow calculation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_stage1 <= 0;
        valid_stage1 <= 0;
        borrow_stage1 <= 0;
        diff_stage1 <= 0;
        addr_sub_stage1 <= 0;
    end else begin
        addr_stage1 <= addr;
        valid_stage1 <= 1'b1;
        
        // First level of borrow subtractor
        borrow_stage1[0] <= 1'b0;
        diff_stage1[0] <= addr[0] ^ 1'b0;
        borrow_stage1[1] <= (~addr[0]) & 1'b0;
    end
end

// Stage 2: Complete borrow subtractor and initial decode
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_stage2 <= 0;
        valid_stage2 <= 0;
        borrow_stage2 <= 0;
        diff_stage2 <= 0;
        addr_sub_stage2 <= 0;
        data_stage1 <= 0;
    end else begin
        addr_stage2 <= addr_stage1;
        valid_stage2 <= valid_stage1;
        
        // Second level of borrow subtractor
        borrow_stage2[2] <= (~addr_stage1[1]) & borrow_stage1[1];
        diff_stage2[1] <= addr_stage1[1] ^ borrow_stage1[1];
        
        borrow_stage2[3] <= (~addr_stage1[2]) & borrow_stage2[2];
        diff_stage2[2] <= addr_stage1[2] ^ borrow_stage2[2];
        
        diff_stage2[3] <= addr_stage1[3] ^ borrow_stage2[3];
        addr_sub_stage2 <= diff_stage2;
        
        // Initial decode
        case(addr_sub_stage2)
            4'h0: data_stage1 <= 8'h01;
            4'h4: data_stage1 <= 8'h02;
            default: data_stage1 <= 8'h00;
        endcase
    end
end

// Stage 3: Final output register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data <= 0;
        valid <= 0;
    end else begin
        data <= data_stage1;
        valid <= valid_stage2;
    end
end

endmodule