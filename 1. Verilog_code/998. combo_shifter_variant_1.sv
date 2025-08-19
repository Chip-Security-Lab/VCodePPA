//SystemVerilog
module combo_shifter(
    input              clk,
    input              rst_n,
    input      [15:0]  data,
    input      [3:0]   shift_val,
    input      [1:0]   op_mode,    // 00:LSL, 01:LSR, 10:ASR, 11:ROR
    output reg [15:0]  result
);

    // Stage 1: Latch inputs
    reg [15:0]  data_latched;
    reg [3:0]   shift_val_latched;
    reg [1:0]   op_mode_latched;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_latched      <= 16'b0;
        end else begin
            data_latched      <= data;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_val_latched <= 4'b0;
        end else begin
            shift_val_latched <= shift_val;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            op_mode_latched   <= 2'b0;
        end else begin
            op_mode_latched   <= op_mode;
        end
    end

    // Stage 2: Compute shift results in parallel
    reg [15:0] lsl_result;
    reg [15:0] lsr_result;
    reg [15:0] asr_result;
    reg [15:0] ror_result;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lsl_result <= 16'b0;
        end else begin
            lsl_result <= data_latched << shift_val_latched;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lsr_result <= 16'b0;
        end else begin
            lsr_result <= data_latched >> shift_val_latched;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            asr_result <= 16'b0;
        end else begin
            asr_result <= $signed(data_latched) >>> shift_val_latched;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ror_result <= 16'b0;
        end else begin
            ror_result <= (data_latched >> shift_val_latched) | (data_latched << (16 - shift_val_latched));
        end
    end

    // Stage 3: Select result based on op_mode
    reg [15:0] result_selected;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_selected <= 16'b0;
        end else begin
            case (op_mode_latched)
                2'b00: result_selected <= lsl_result;
                2'b01: result_selected <= lsr_result;
                2'b10: result_selected <= asr_result;
                2'b11: result_selected <= ror_result;
                default: result_selected <= 16'b0;
            endcase
        end
    end

    // Stage 4: Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 16'b0;
        end else begin
            result <= result_selected;
        end
    end

endmodule