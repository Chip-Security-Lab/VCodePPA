//SystemVerilog
module serializer_mux (
    input  wire        clk,               // Clock signal
    input  wire        rst_n,             // Active low reset
    input  wire        load,              // Load parallel data
    input  wire [7:0]  parallel_in,       // Parallel input data
    output wire        serial_out,        // Serial output
    output wire        valid_out          // Output valid flag
);

    // Stage 1: Input capture and control
    reg [7:0] parallel_in_r;
    reg       load_r;
    reg       valid_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parallel_in_r <= 8'b0;
            load_r        <= 1'b0;
            valid_r       <= 1'b0;
        end else begin
            parallel_in_r <= parallel_in;
            load_r        <= load;
            valid_r       <= load;
        end
    end

    // Stage 2: Shift and valid logic (path-balanced)
    reg [7:0] shift_reg;
    reg       valid_shift;

    wire      shift_enable;
    assign    shift_enable = load_r | valid_shift;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg   <= 8'b0;
            valid_shift <= 1'b0;
        end else begin
            if (load_r) begin
                shift_reg   <= parallel_in_r;
                valid_shift <= valid_r;
            end else if (valid_shift) begin
                shift_reg   <= {shift_reg[6:0], 1'b0};
                valid_shift <= valid_shift;
            end else begin
                shift_reg   <= shift_reg;
                valid_shift <= 1'b0;
            end
        end
    end

    // Stage 3: Output register for serial data and valid (no logic chain)
    reg serial_out_reg;
    reg valid_out_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            serial_out_reg <= 1'b0;
            valid_out_reg  <= 1'b0;
        end else begin
            serial_out_reg <= shift_reg[7];
            valid_out_reg  <= valid_shift;
        end
    end

    assign serial_out = serial_out_reg;
    assign valid_out  = valid_out_reg;

endmodule