//SystemVerilog - IEEE 1364-2005 Standard
// Top-level module
module d_ff_enable #(
    parameter RESET_VALUE = 1'b0
)(
    input  wire       clock,    // System clock
    input  wire       enable,   // Enable signal
    input  wire       data_in,  // Input data
    output wire       data_out  // Output data
);
    
    // Internal interface signals
    wire stage1_enable;
    wire stage1_data;
    
    // Instantiate pipeline stages
    pipeline_register #(
        .WIDTH(2)
    ) input_stage (
        .clock     (clock),
        .data_in   ({enable, data_in}),
        .data_out  ({stage1_enable, stage1_data})
    );
    
    // Instantiate conditional update module
    conditional_update #(
        .RESET_VALUE(RESET_VALUE)
    ) update_stage (
        .clock      (clock),
        .enable     (stage1_enable),
        .data_in    (stage1_data),
        .data_out   (data_out)
    );

endmodule

// Generic pipeline register module
module pipeline_register #(
    parameter WIDTH = 1
)(
    input  wire                clock,
    input  wire [WIDTH-1:0]    data_in,
    output reg  [WIDTH-1:0]    data_out
);

    always @(posedge clock) begin
        data_out <= data_in;
    end

endmodule

// Conditional data update module
module conditional_update #(
    parameter RESET_VALUE = 1'b0
)(
    input  wire       clock,
    input  wire       enable,
    input  wire       data_in,
    output reg        data_out
);

    // Initialize with reset value
    initial begin
        data_out = RESET_VALUE;
    end

    always @(posedge clock) begin
        if (enable)
            data_out <= data_in;
    end

endmodule