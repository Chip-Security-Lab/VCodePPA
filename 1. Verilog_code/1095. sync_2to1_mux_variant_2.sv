//SystemVerilog
module valid_ready_2to1_mux (
    input wire clk,                               // Clock signal
    input wire rst_n,                             // Active low reset
    input wire [7:0] data_a,                      // Data input A
    input wire valid_a,                           // Valid signal for data_a
    input wire [7:0] data_b,                      // Data input B
    input wire valid_b,                           // Valid signal for data_b
    input wire sel,                               // Selection bit
    output reg [7:0] data_out,                    // Output data
    output reg valid_out,                         // Output valid
    input wire ready_out,                         // Output ready
    output reg ready_a,                           // Ready for data_a
    output reg ready_b                            // Ready for data_b
);

    // Pipeline stage 1: mux selection and valid
    reg [7:0] mux_data_stage1;
    reg mux_valid_stage1;
    reg sel_stage1;
    reg ready_out_stage1;
    reg valid_a_stage1, valid_b_stage1;

    // Pipeline stage 2: handshake and output
    reg [7:0] mux_data_stage2;
    reg mux_valid_stage2;
    reg sel_stage2;
    reg valid_a_stage2, valid_b_stage2;

    // Pipeline stage 1: Register muxed data and control signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mux_data_stage1   <= 8'd0;
            mux_valid_stage1  <= 1'b0;
            sel_stage1        <= 1'b0;
            ready_out_stage1  <= 1'b0;
            valid_a_stage1    <= 1'b0;
            valid_b_stage1    <= 1'b0;
        end else begin
            if (sel) begin
                mux_data_stage1  <= data_b;
                mux_valid_stage1 <= valid_b;
            end else begin
                mux_data_stage1  <= data_a;
                mux_valid_stage1 <= valid_a;
            end
            sel_stage1       <= sel;
            ready_out_stage1 <= ready_out;
            valid_a_stage1   <= valid_a;
            valid_b_stage1   <= valid_b;
        end
    end

    // Pipeline stage 2: Register handshake logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mux_data_stage2   <= 8'd0;
            mux_valid_stage2  <= 1'b0;
            sel_stage2        <= 1'b0;
            valid_a_stage2    <= 1'b0;
            valid_b_stage2    <= 1'b0;
        end else begin
            mux_data_stage2   <= mux_data_stage1;
            mux_valid_stage2  <= mux_valid_stage1;
            sel_stage2        <= sel_stage1;
            valid_a_stage2    <= valid_a_stage1;
            valid_b_stage2    <= valid_b_stage1;
        end
    end

    // Output logic with valid-ready handshake (pipeline output)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out  <= 8'd0;
            valid_out <= 1'b0;
        end else if (mux_valid_stage2 && ready_out) begin
            data_out  <= mux_data_stage2;
            valid_out <= 1'b1;
        end else if (valid_out && ready_out) begin
            valid_out <= 1'b0;
        end
    end

    // Ready signal generation for inputs (pipeline aligned)
    always @(*) begin
        ready_a = 1'b0;
        ready_b = 1'b0;

        // Align ready signals with pipeline stage
        if (!sel_stage2 && ready_out && valid_a_stage2) begin
            ready_a = 1'b1;
        end else if (sel_stage2 && ready_out && valid_b_stage2) begin
            ready_b = 1'b1;
        end
    end

endmodule