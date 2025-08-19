//SystemVerilog
module serializer_mux (
    input  wire        clk,               // Clock signal
    input  wire        rst_n,             // Active-low reset
    input  wire        load,              // Load parallel data
    input  wire [7:0]  parallel_in,       // Parallel input data
    input  wire        flush,             // Flush pipeline
    output wire        serial_out,        // Serial output
    output wire        valid_out          // Serial data valid
);

    // Stage 1+2: Move input registers after combination logic (forward register retiming)
    reg [7:0]  shift_reg_stage2;
    reg        valid_stage2;
    reg        flush_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_stage2 <= 8'b0;
            valid_stage2     <= 1'b0;
            flush_stage2     <= 1'b0;
        end else if (flush) begin
            shift_reg_stage2 <= 8'b0;
            valid_stage2     <= 1'b0;
            flush_stage2     <= 1'b0;
        end else begin
            if (load) begin
                shift_reg_stage2 <= parallel_in;
                valid_stage2     <= 1'b1;
            end else if (valid_stage2) begin
                shift_reg_stage2 <= {shift_reg_stage2[6:0], 1'b0};
                valid_stage2     <= |shift_reg_stage2[6:0];
            end
            flush_stage2 <= flush;
        end
    end

    // Stage 3: Output register for serial output and valid
    reg serial_out_stage3;
    reg valid_stage3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            serial_out_stage3 <= 1'b0;
            valid_stage3      <= 1'b0;
        end else if (flush_stage2) begin
            serial_out_stage3 <= 1'b0;
            valid_stage3      <= 1'b0;
        end else begin
            serial_out_stage3 <= shift_reg_stage2[7];
            valid_stage3      <= valid_stage2;
        end
    end

    assign serial_out = serial_out_stage3;
    assign valid_out  = valid_stage3;

endmodule