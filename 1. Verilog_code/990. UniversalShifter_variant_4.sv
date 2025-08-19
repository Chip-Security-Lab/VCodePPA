//SystemVerilog
module UniversalShifter #(parameter WIDTH=8) (
    input                   clk,
    input                   rst_n,
    input                   start,
    input       [1:0]       mode,         // 00:hold 01:left 10:right 11:load
    input                   serial_in,
    input       [WIDTH-1:0] parallel_in,
    output reg  [WIDTH-1:0] data_reg,
    output                  valid_out
);

// Internal pipeline registers
reg [1:0]               mode_stage2;
reg                     serial_in_stage2;
reg [WIDTH-1:0]         parallel_in_stage2;
reg [WIDTH-1:0]         data_reg_stage2;
reg                     valid_stage2;
reg [WIDTH-1:0]         data_reg_stage3;
reg                     valid_stage3;

// Merged sequential logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mode_stage2         <= 2'b00;
        serial_in_stage2    <= 1'b0;
        parallel_in_stage2  <= {WIDTH{1'b0}};
        data_reg_stage2     <= {WIDTH{1'b0}};
        valid_stage2        <= 1'b0;
        data_reg_stage3     <= {WIDTH{1'b0}};
        valid_stage3        <= 1'b0;
        data_reg            <= {WIDTH{1'b0}};
    end else begin
        // Stage 2: Pipeline input signals and current data_reg
        mode_stage2         <= mode;
        serial_in_stage2    <= serial_in;
        parallel_in_stage2  <= parallel_in;
        data_reg_stage2     <= data_reg;
        valid_stage2        <= start;

        // Stage 3: Shift or load operation
        case (mode_stage2)
            2'b01: data_reg_stage3 <= {data_reg_stage2[WIDTH-2:0], serial_in_stage2}; // left shift
            2'b10: data_reg_stage3 <= {serial_in_stage2, data_reg_stage2[WIDTH-1:1]}; // right shift
            2'b11: data_reg_stage3 <= parallel_in_stage2;                             // load parallel
            default: data_reg_stage3 <= data_reg_stage2;                              // hold
        endcase
        valid_stage3 <= valid_stage2;

        // Output register update
        if (valid_stage3) begin
            data_reg <= data_reg_stage3;
        end
    end
end

assign valid_out = valid_stage3;

endmodule