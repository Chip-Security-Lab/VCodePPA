//SystemVerilog
module i2c_timeout_master(
    input clk,
    input rst_n,
    input [6:0] slave_addr,
    input [7:0] write_data,
    input enable,
    output reg [7:0] read_data,
    output reg busy,
    output reg timeout_error,
    inout scl,
    inout sda
);
    localparam TIMEOUT = 16'd1000;

    // Pipeline Stage 1: Input Latching
    reg [6:0] slave_addr_stage1;
    reg [7:0] write_data_stage1;
    reg enable_stage1;
    reg [3:0] state_stage1;
    reg busy_stage1;

    // Pipeline Stage 1.5: Midpoint Pipeline Register for Key Path Cutting
    reg [6:0] slave_addr_stage1p5;
    reg [7:0] write_data_stage1p5;
    reg enable_stage1p5;
    reg [3:0] state_stage1p5;
    reg busy_stage1p5;

    // Pipeline Stage 2: Timeout Counter and Error Detection
    reg [15:0] timeout_counter_stage2;
    reg timeout_error_stage2;
    reg [3:0] state_stage2;
    reg enable_stage2;
    reg busy_stage2;

    // Pipeline Stage 2.5: Midpoint Pipeline Register for Key Path Cutting
    reg [15:0] timeout_counter_stage2p5;
    reg timeout_error_stage2p5;
    reg [3:0] state_stage2p5;
    reg enable_stage2p5;
    reg busy_stage2p5;

    // Pipeline Stage 3: I2C Control Signals
    reg sda_out_stage3, scl_out_stage3, sda_oe_stage3;
    reg [3:0] state_stage3;
    reg enable_stage3;
    reg busy_stage3;
    reg timeout_error_stage3;

    // Output registers
    reg [7:0] read_data_stage4;
    reg busy_stage4;
    reg timeout_error_stage4;

    // Assignments for tri-state control
    assign scl = scl_out_stage3 ? 1'bz : 1'b0;
    assign sda = sda_oe_stage3 ? 1'bz : sda_out_stage3;

    // Stage 1: Capture inputs and initial state
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            slave_addr_stage1 <= 7'd0;
            write_data_stage1 <= 8'd0;
            enable_stage1     <= 1'b0;
            state_stage1      <= 4'd0;
            busy_stage1       <= 1'b0;
        end else begin
            slave_addr_stage1 <= slave_addr;
            write_data_stage1 <= write_data;
            enable_stage1     <= enable;
            state_stage1      <= 4'd0; // Ready state
            busy_stage1       <= enable ? 1'b1 : 1'b0;
        end
    end

    // Stage 1.5: Pipeline register to cut key path (input propagation)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            slave_addr_stage1p5 <= 7'd0;
            write_data_stage1p5 <= 8'd0;
            enable_stage1p5     <= 1'b0;
            state_stage1p5      <= 4'd0;
            busy_stage1p5       <= 1'b0;
        end else begin
            slave_addr_stage1p5 <= slave_addr_stage1;
            write_data_stage1p5 <= write_data_stage1;
            enable_stage1p5     <= enable_stage1;
            state_stage1p5      <= state_stage1;
            busy_stage1p5       <= busy_stage1;
        end
    end

    // Stage 2: Timeout Counter and Error Logic (split to enable pipelining)
    reg timeout_counter_enable_stage2;
    reg timeout_counter_reset_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timeout_counter_stage2 <= 16'd0;
            timeout_error_stage2   <= 1'b0;
            state_stage2           <= 4'd0;
            enable_stage2          <= 1'b0;
            busy_stage2            <= 1'b0;
        end else begin
            state_stage2      <= state_stage1p5;
            enable_stage2     <= enable_stage1p5;
            busy_stage2       <= busy_stage1p5;
            timeout_counter_enable_stage2 <= (state_stage1p5 != 4'd0 && enable_stage1p5);
            timeout_counter_reset_stage2  <= ~(state_stage1p5 != 4'd0 && enable_stage1p5);

            if (state_stage1p5 != 4'd0 && enable_stage1p5) begin
                timeout_counter_stage2 <= timeout_counter_stage2 + 1'b1;
                if (timeout_counter_stage2 >= TIMEOUT) begin
                    timeout_error_stage2 <= 1'b1;
                end else begin
                    timeout_error_stage2 <= 1'b0;
                end
            end else begin
                timeout_counter_stage2 <= 16'd0;
                timeout_error_stage2   <= 1'b0;
            end
        end
    end

    // Stage 2.5: Pipeline register to cut key path for timeout logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timeout_counter_stage2p5 <= 16'd0;
            timeout_error_stage2p5   <= 1'b0;
            state_stage2p5           <= 4'd0;
            enable_stage2p5          <= 1'b0;
            busy_stage2p5            <= 1'b0;
        end else begin
            timeout_counter_stage2p5 <= timeout_counter_stage2;
            timeout_error_stage2p5   <= timeout_error_stage2;
            state_stage2p5           <= state_stage2;
            enable_stage2p5          <= enable_stage2;
            busy_stage2p5            <= busy_stage2;
        end
    end

    // Stage 3: I2C Control Signal Preparation (placeholder for actual I2C logic)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sda_out_stage3       <= 1'b1;
            scl_out_stage3       <= 1'b1;
            sda_oe_stage3        <= 1'b1;
            state_stage3         <= 4'd0;
            enable_stage3        <= 1'b0;
            busy_stage3          <= 1'b0;
            timeout_error_stage3 <= 1'b0;
        end else begin
            state_stage3         <= state_stage2p5;
            enable_stage3        <= enable_stage2p5;
            busy_stage3          <= busy_stage2p5;
            timeout_error_stage3 <= timeout_error_stage2p5;
            // Placeholder: actual I2C state machine logic would be pipelined here
            sda_out_stage3       <= 1'b1; // Idle state
            scl_out_stage3       <= 1'b1; // Idle state
            sda_oe_stage3        <= 1'b1; // Not driving
        end
    end

    // Stage 4: Output Register Latching
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_data_stage4      <= 8'd0;
            busy_stage4           <= 1'b0;
            timeout_error_stage4  <= 1'b0;
        end else begin
            read_data_stage4      <= 8'd0; // Placeholder, actual read data in real implementation
            busy_stage4           <= busy_stage3;
            timeout_error_stage4  <= timeout_error_stage3;
        end
    end

    // Final output assignments
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_data     <= 8'd0;
            busy          <= 1'b0;
            timeout_error <= 1'b0;
        end else begin
            read_data     <= read_data_stage4;
            busy          <= busy_stage4;
            timeout_error <= timeout_error_stage4;
        end
    end

endmodule