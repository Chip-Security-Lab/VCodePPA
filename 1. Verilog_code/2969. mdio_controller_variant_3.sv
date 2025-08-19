//SystemVerilog
module mdio_controller #(
    parameter PHY_ADDR = 5'h01,
    parameter CLK_DIV = 64
)(
    input clk,
    input rst,
    input [4:0] reg_addr,
    input [15:0] data_in,
    input write_en,
    output reg [15:0] data_out,
    output reg mdio_done,
    inout mdio,
    output mdc
);
    // Clock divider pipeline
    reg [9:0] clk_counter;
    reg [9:0] clk_counter_buf1, clk_counter_buf2;
    reg mdc_stage1, mdc_stage2, mdc_stage3;
    
    // Bit counter pipeline with buffers
    reg [3:0] bit_count_stage1, bit_count_stage2, bit_count_stage3;
    reg [3:0] bit_count_stage1_buf1, bit_count_stage1_buf2;
    
    // Shift register pipeline with buffers
    reg [31:0] shift_reg_stage1, shift_reg_stage2, shift_reg_stage3;
    reg [31:0] shift_reg_stage1_buf1, shift_reg_stage1_buf2;
    
    // MDIO control pipeline
    reg mdio_oe_stage1, mdio_oe_stage2, mdio_oe_stage3;
    reg mdio_out_stage1, mdio_out_stage2, mdio_out_stage3;
    
    // Pipeline control signals
    reg write_en_stage1, write_en_stage2;
    reg bit_processing_stage1, bit_processing_stage2, bit_processing_stage3;
    reg clk_cycle_complete_stage1, clk_cycle_complete_stage2;
    
    // Input sampling registers
    reg [4:0] reg_addr_sampled;
    reg [15:0] data_in_sampled;
    
    // Output assignments
    assign mdc = mdc_stage3;
    assign mdio = mdio_oe_stage3 ? mdio_out_stage3 : 1'bz;

    // Stage 1: Clock division and input processing
    always @(posedge clk) begin
        if (rst) begin
            clk_counter <= 0;
            clk_counter_buf1 <= 0;
            clk_counter_buf2 <= 0;
            mdc_stage1 <= 0;
            write_en_stage1 <= 0;
            bit_processing_stage1 <= 0;
            reg_addr_sampled <= 0;
            data_in_sampled <= 0;
        end else begin
            clk_counter <= clk_counter + 1;
            
            // Buffer the high fanout clk_counter signal
            clk_counter_buf1 <= clk_counter;
            clk_counter_buf2 <= clk_counter;
            
            // Generate MDC clock in stage 1
            mdc_stage1 <= clk_counter[CLK_DIV/2];
            
            // Sample inputs on write_en
            if (write_en && !mdio_done) begin
                write_en_stage1 <= 1;
                reg_addr_sampled <= reg_addr;
                data_in_sampled <= data_in;
            end else begin
                write_en_stage1 <= 0;
            end
            
            // Detect clock cycle completion
            clk_cycle_complete_stage1 <= (clk_counter_buf1 == CLK_DIV-1);
        end
    end

    // Stage 2: Bit counting and shift register preparation
    always @(posedge clk) begin
        if (rst) begin
            bit_count_stage1 <= 0;
            bit_count_stage1_buf1 <= 0;
            bit_count_stage1_buf2 <= 0;
            bit_count_stage2 <= 0;
            shift_reg_stage1 <= 0;
            shift_reg_stage1_buf1 <= 0;
            shift_reg_stage1_buf2 <= 0;
            shift_reg_stage2 <= 0;
            mdio_oe_stage1 <= 0;
            mdio_oe_stage2 <= 0;
            mdio_out_stage1 <= 0;
            mdio_out_stage2 <= 0;
            write_en_stage2 <= 0;
            bit_processing_stage2 <= 0;
            clk_cycle_complete_stage2 <= 0;
        end else begin
            // Pipeline control signals
            mdc_stage2 <= mdc_stage1;
            write_en_stage2 <= write_en_stage1;
            bit_processing_stage2 <= bit_processing_stage1;
            clk_cycle_complete_stage2 <= clk_cycle_complete_stage1;
            
            // Buffer high fanout signals
            bit_count_stage1_buf1 <= bit_count_stage1;
            bit_count_stage1_buf2 <= bit_count_stage1;
            shift_reg_stage1_buf1 <= shift_reg_stage1;
            shift_reg_stage1_buf2 <= shift_reg_stage1;
            
            // Initialize shift register on write_en
            if (write_en_stage1 && !bit_processing_stage1) begin
                shift_reg_stage1 <= {2'b01, PHY_ADDR, reg_addr_sampled, 2'b10, data_in_sampled};
                mdio_oe_stage1 <= 1;
                bit_processing_stage1 <= 1;
                bit_count_stage1 <= 0;
            end
            
            // Process bits
            if (clk_cycle_complete_stage1 && bit_processing_stage1) begin
                if (bit_count_stage1_buf1 < 32) begin
                    shift_reg_stage1 <= {shift_reg_stage1_buf1[30:0], mdio};
                    bit_count_stage1 <= bit_count_stage1_buf2 + 1;
                    mdio_out_stage1 <= shift_reg_stage1_buf2[31];
                end
            end
            
            // Pipeline registers to stage 2
            bit_count_stage2 <= bit_count_stage1_buf2;
            shift_reg_stage2 <= shift_reg_stage1_buf1;
            mdio_oe_stage2 <= mdio_oe_stage1;
            mdio_out_stage2 <= mdio_out_stage1;
        end
    end

    // Stage 3: Output generation and completion detection
    always @(posedge clk) begin
        if (rst) begin
            bit_count_stage3 <= 0;
            shift_reg_stage3 <= 0;
            mdio_oe_stage3 <= 0;
            mdio_out_stage3 <= 0;
            bit_processing_stage3 <= 0;
            data_out <= 0;
            mdio_done <= 0;
            mdc_stage3 <= 0;
        end else begin
            // Pipeline control signals
            mdc_stage3 <= mdc_stage2;
            bit_count_stage3 <= bit_count_stage2;
            shift_reg_stage3 <= shift_reg_stage2;
            mdio_oe_stage3 <= mdio_oe_stage2;
            mdio_out_stage3 <= mdio_out_stage2;
            bit_processing_stage3 <= bit_processing_stage2;
            
            // Detect completion
            if (clk_cycle_complete_stage2 && bit_processing_stage2) begin
                if (bit_count_stage2 >= 32) begin
                    data_out <= shift_reg_stage2[15:0];
                    mdio_done <= 1;
                    mdio_oe_stage3 <= 0;
                    bit_processing_stage3 <= 0;
                end
            end
            
            // Reset done signal on new write
            if (write_en) begin
                mdio_done <= 0;
            end
        end
    end
endmodule