//SystemVerilog
// IEEE 1364-2005 Verilog standard
module ParityShift #(parameter DATA_BITS=7) (
    input wire clk,
    input wire rst,
    input wire sin,
    input wire valid_in,
    output wire valid_out,
    output wire [DATA_BITS:0] sreg_out // [7:0] for 7+1 parity
);

    // Buffered clock and reset signals to reduce fanout
    wire clk_buf1, clk_buf2, clk_buf3;
    wire rst_buf1, rst_buf2, rst_buf3;
    
    // Clock and reset buffers for better timing
    assign clk_buf1 = clk;
    assign clk_buf2 = clk;
    assign clk_buf3 = clk;
    
    assign rst_buf1 = rst;
    assign rst_buf2 = rst;
    assign rst_buf3 = rst;

    // Stage 1: Input capture and initial shift
    reg [DATA_BITS-1:0] stage1_data;
    reg stage1_valid;
    
    // Stage 2: Parity calculation
    reg [DATA_BITS-1:0] stage2_data;
    reg stage2_sin;
    reg stage2_valid;
    
    // Parity calculation with pipeline registers to reduce fanout
    wire [3:0] parity_partial;
    reg [3:0] parity_reg;
    wire stage2_parity;
    
    // Stage 3: Output formation
    reg [DATA_BITS:0] stage3_sreg;
    reg stage3_valid;
    
    // Split parity calculation into smaller groups to reduce critical path
    assign parity_partial[0] = ^stage2_data[1:0];
    assign parity_partial[1] = ^stage2_data[3:2];
    assign parity_partial[2] = ^stage2_data[5:4];
    assign parity_partial[3] = (DATA_BITS > 6) ? stage2_data[6] : 1'b0;
    
    // Final parity calculation from partial results
    assign stage2_parity = ^parity_reg;
    
    // Output assignments
    assign sreg_out = stage3_sreg;
    assign valid_out = stage3_valid;
    
    // Parity partial results registration
    always @(posedge clk_buf2 or posedge rst_buf2) begin
        if (rst_buf2) begin
            parity_reg <= 4'b0000;
        end
        else begin
            parity_reg <= parity_partial;
        end
    end
    
    // Stage 1: Input capture and initial processing
    always @(posedge clk_buf1 or posedge rst_buf1) begin
        if (rst_buf1) begin
            stage1_data <= {DATA_BITS{1'b0}};
            stage1_valid <= 1'b0;
        end
        else begin
            if (valid_in) begin
                stage1_data <= {sin, stage1_data[DATA_BITS-1:1]};
                stage1_valid <= 1'b1;
            end
            else begin
                stage1_valid <= 1'b0;
            end
        end
    end
    
    // Stage 2: Parity calculation stage
    always @(posedge clk_buf2 or posedge rst_buf2) begin
        if (rst_buf2) begin
            stage2_data <= {DATA_BITS{1'b0}};
            stage2_sin <= 1'b0;
            stage2_valid <= 1'b0;
        end
        else begin
            stage2_data <= stage1_data;
            stage2_sin <= sin; // Capture input bit for next stage
            stage2_valid <= stage1_valid;
        end
    end
    
    // Stage 3: Output formation
    always @(posedge clk_buf3 or posedge rst_buf3) begin
        if (rst_buf3) begin
            stage3_sreg <= {(DATA_BITS+1){1'b0}};
            stage3_valid <= 1'b0;
        end
        else begin
            if (stage2_valid) begin
                stage3_sreg <= {stage2_parity, stage2_data};
                stage3_valid <= 1'b1;
            end
            else begin
                stage3_valid <= 1'b0;
            end
        end
    end

endmodule