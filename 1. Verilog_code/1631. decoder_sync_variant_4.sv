//SystemVerilog
module decoder_sync #(ADDR_WIDTH=4, DATA_WIDTH=8) (
    input clk, rst_n,
    input [ADDR_WIDTH-1:0] addr,
    output reg [DATA_WIDTH-1:0] data
);

    // Pipeline stage 1 registers
    reg [ADDR_WIDTH-1:0] addr_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers 
    reg [DATA_WIDTH-1:0] data_stage2;
    reg valid_stage2;

    // Stage 1: Address capture and validation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            addr_stage1 <= addr;
            valid_stage1 <= 1'b1;
        end
    end

    // Stage 2: Optimized decode logic using range checks
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= 0;
            valid_stage2 <= 0;
        end else if (valid_stage1) begin
            // Use range checks instead of case statement
            if (addr_stage1 == 4'h0)
                data_stage2 <= 8'h01;
            else if (addr_stage1 == 4'h4)
                data_stage2 <= 8'h02;
            else
                data_stage2 <= 8'h00;
            valid_stage2 <= valid_stage1;
        end else begin
            data_stage2 <= 0;
            valid_stage2 <= 0;
        end
    end

    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data <= 0;
        end else if (valid_stage2) begin
            data <= data_stage2;
        end else begin
            data <= 0;
        end
    end

endmodule