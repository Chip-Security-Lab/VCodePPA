//SystemVerilog
module asymmetric_regfile #(
    parameter WR_DW = 64,
    parameter RD_DW = 32
)(
    input clk,
    input rst_n,  // Reset signal (active low)
    
    // Write port interface
    input wr_valid,
    input wr_en,
    input [2:0] wr_addr,
    input [WR_DW-1:0] din,
    output reg wr_ready,
    
    // Read port interface
    input rd_valid,
    input [3:0] rd_addr,
    output reg [RD_DW-1:0] dout,
    output reg rd_valid_out
);

    // Memory array
    reg [WR_DW-1:0] mem [0:7];

    // Pipeline stage 1 registers - Address decode
    reg [2:0] rd_addr_s1;
    reg sel_high_s1;
    reg rd_valid_s1;
    
    // Pipeline stage 2 registers - Memory read
    reg [RD_DW-1:0] mem_low_s2;
    reg [RD_DW-1:0] mem_high_s2;
    reg sel_high_s2;
    reg rd_valid_s2;
    
    // Write logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ready <= 1'b1;
        end else begin
            wr_ready <= 1'b1; // Always ready to accept new write
            
            if (wr_valid && wr_en) begin
                mem[wr_addr] <= din;
            end
        end
    end
    
    // Read pipeline - Stage 1: Address decode
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_addr_s1 <= 3'b0;
            sel_high_s1 <= 1'b0;
            rd_valid_s1 <= 1'b0;
        end else begin
            rd_valid_s1 <= rd_valid;
            
            if (rd_valid) begin
                rd_addr_s1 <= rd_addr[2:0];
                sel_high_s1 <= rd_addr[3];
            end
        end
    end
    
    // Read pipeline - Stage 2: Memory read
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_low_s2 <= {RD_DW{1'b0}};
            mem_high_s2 <= {RD_DW{1'b0}};
            sel_high_s2 <= 1'b0;
            rd_valid_s2 <= 1'b0;
        end else begin
            rd_valid_s2 <= rd_valid_s1;
            sel_high_s2 <= sel_high_s1;
            
            if (rd_valid_s1) begin
                mem_low_s2 <= mem[rd_addr_s1][RD_DW-1:0];
                mem_high_s2 <= mem[rd_addr_s1][WR_DW-1:RD_DW];
            end
        end
    end
    
    // Read pipeline - Stage 3: Output mux
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout <= {RD_DW{1'b0}};
            rd_valid_out <= 1'b0;
        end else begin
            rd_valid_out <= rd_valid_s2;
            
            if (rd_valid_s2) begin
                dout <= sel_high_s2 ? mem_high_s2 : mem_low_s2;
            end
        end
    end

endmodule