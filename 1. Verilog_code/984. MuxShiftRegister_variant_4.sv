//SystemVerilog
module MuxShiftRegister #(parameter WIDTH=8) (
    input                  clk,
    input                  rst_n,
    input                  sel,
    input      [1:0]       serial_in,
    input                  valid_in,
    output reg [WIDTH-1:0] data_out,
    output                 valid_out
);

    // Stage 1: Mux selection - split into two pipeline stages for higher frequency
    reg                    serial_in_sel_stage1;
    reg                    valid_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            serial_in_sel_stage1 <= 1'b0;
            valid_stage1         <= 1'b0;
        end else begin
            // Simple assignment, but kept in stage1 for pipeline balance
            serial_in_sel_stage1 <= serial_in[0];
            valid_stage1         <= valid_in;
        end
    end

    reg                    serial_in_sel_stage2;
    reg                    valid_stage2;
    reg                    sel_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            serial_in_sel_stage2 <= 1'b0;
            valid_stage2         <= 1'b0;
            sel_stage2           <= 1'b0;
        end else begin
            // Delayed selection and sel for mux
            serial_in_sel_stage2 <= serial_in_sel_stage1;
            valid_stage2         <= valid_stage1;
            sel_stage2           <= sel;
        end
    end

    // Stage 2.5: Mux operation (now separated from input latch for timing)
    reg                    selected_bit_stage3;
    reg                    valid_stage3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            selected_bit_stage3 <= 1'b0;
            valid_stage3        <= 1'b0;
        end else begin
            selected_bit_stage3 <= sel_stage2 ? serial_in[1] : serial_in_sel_stage2;
            valid_stage3        <= valid_stage2;
        end
    end

    // Stage 3: Shift register operation (split into two pipeline stages)
    reg [WIDTH-1:0]        shift_reg_stage4;
    reg                    valid_stage4;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_stage4 <= {WIDTH{1'b0}};
            valid_stage4     <= 1'b0;
        end else if (valid_stage3) begin
            shift_reg_stage4 <= {shift_reg_stage4[WIDTH-2:0], selected_bit_stage3};
            valid_stage4     <= valid_stage3;
        end else begin
            valid_stage4     <= 1'b0;
        end
    end

    // Stage 4: Output register
    reg [WIDTH-1:0]        data_out_stage5;
    reg                    valid_stage5;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_stage5 <= {WIDTH{1'b0}};
            valid_stage5    <= 1'b0;
        end else if (valid_stage4) begin
            data_out_stage5 <= shift_reg_stage4;
            valid_stage5    <= valid_stage4;
        end else begin
            valid_stage5    <= 1'b0;
        end
    end

    // Output assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {WIDTH{1'b0}};
        end else if (valid_stage5) begin
            data_out <= data_out_stage5;
        end
    end

    assign valid_out = valid_stage5;

endmodule