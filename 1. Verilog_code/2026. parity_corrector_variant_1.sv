//SystemVerilog
// Top-level module: Parity Corrector Pipeline (Hierarchical & Modularized)
module parity_corrector (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  data_in,
    output wire [7:0]  data_out,
    output wire        error
);

    // Pipeline Stage 1: Input Register
    wire [7:0] data_stage1;
    input_register u_input_register (
        .clk       (clk),
        .rst_n     (rst_n),
        .data_in   (data_in),
        .data_out  (data_stage1)
    );

    // Pipeline Stage 2: Parity Calculation
    wire        parity_stage2;
    parity_calculator u_parity_calculator (
        .data_in   (data_stage1),
        .parity_out(parity_stage2)
    );

    // Pipeline Stage 2 -> 3: Parity and Data Register
    wire        parity_stage3;
    wire [7:0]  data_stage3;
    parity_data_register u_parity_data_register (
        .clk           (clk),
        .rst_n         (rst_n),
        .parity_in     (parity_stage2),
        .data_in       (data_stage1),
        .parity_out    (parity_stage3),
        .data_out      (data_stage3)
    );

    // Pipeline Stage 3: Error Signal Generation
    wire        error_stage4;
    error_signal u_error_signal (
        .parity_in (parity_stage3),
        .error_out (error_stage4)
    );

    // Pipeline Stage 3 -> 4: Error and Data Register
    wire        error_stage4_reg;
    wire [7:0]  data_stage4;
    error_data_register u_error_data_register (
        .clk           (clk),
        .rst_n         (rst_n),
        .error_in      (error_stage4),
        .data_in       (data_stage3),
        .error_out     (error_stage4_reg),
        .data_out      (data_stage4)
    );

    // Pipeline Stage 4: Data Correction
    data_corrector u_data_corrector (
        .data_in (data_stage4),
        .error_in(error_stage4_reg),
        .data_out(data_out)
    );

    // Output Error Signal: Registered for timing consistency
    assign error = error_stage4_reg;

endmodule

//------------------------------------------------------------------------------
// Submodule: Input Register
// Purpose: Registers the input data at the first pipeline stage
//------------------------------------------------------------------------------
module input_register (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  data_in,
    output reg  [7:0]  data_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= 8'b0;
        else
            data_out <= data_in;
    end
endmodule

//------------------------------------------------------------------------------
// Submodule: Parity Calculator
// Purpose: Calculates the parity bit (XOR of all bits in data_in)
//------------------------------------------------------------------------------
module parity_calculator (
    input  wire [7:0] data_in,
    output wire       parity_out
);
    assign parity_out = ^data_in;
endmodule

//------------------------------------------------------------------------------
// Submodule: Parity and Data Register
// Purpose: Registers the calculated parity and data for the next pipeline stage
//------------------------------------------------------------------------------
module parity_data_register (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        parity_in,
    input  wire [7:0]  data_in,
    output reg         parity_out,
    output reg  [7:0]  data_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parity_out <= 1'b0;
            data_out   <= 8'b0;
        end else begin
            parity_out <= parity_in;
            data_out   <= data_in;
        end
    end
endmodule

//------------------------------------------------------------------------------
// Submodule: Error Signal Generator
// Purpose: Passes the parity bit as the error indicator
//------------------------------------------------------------------------------
module error_signal (
    input  wire parity_in,
    output wire error_out
);
    assign error_out = parity_in;
endmodule

//------------------------------------------------------------------------------
// Submodule: Error and Data Register
// Purpose: Registers the error signal and data for the final pipeline stage
//------------------------------------------------------------------------------
module error_data_register (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        error_in,
    input  wire [7:0]  data_in,
    output reg         error_out,
    output reg  [7:0]  data_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            error_out <= 1'b0;
            data_out  <= 8'b0;
        end else begin
            error_out <= error_in;
            data_out  <= data_in;
        end
    end
endmodule

//------------------------------------------------------------------------------
// Submodule: Data Corrector
// Purpose: Outputs original data if no error, else outputs all zeros
//------------------------------------------------------------------------------
module data_corrector (
    input  wire [7:0] data_in,
    input  wire       error_in,
    output wire [7:0] data_out
);
    assign data_out = error_in ? 8'h00 : data_in;
endmodule