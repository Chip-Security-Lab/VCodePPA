//SystemVerilog
// IEEE 1364-2005 Verilog
module onehot_left_shifter #(
    parameter WIDTH = 16
)(
    input wire clk,                  // Clock input for pipelined operation
    input wire rst_n,                // Active-low reset
    input wire [WIDTH-1:0] in_data,
    input wire [WIDTH-1:0] one_hot_control, // One-hot encoded shift amount
    output wire [WIDTH-1:0] out_data
);
    // Internal connections
    wire [WIDTH-1:0] input_stage_data;
    wire [WIDTH-1:0] input_stage_control;
    wire [WIDTH-1:0] shifter_result;
    
    // Input registration stage
    input_register #(
        .WIDTH(WIDTH)
    ) input_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .in_data(in_data),
        .one_hot_control(one_hot_control),
        .reg_data(input_stage_data),
        .reg_control(input_stage_control)
    );
    
    // Shift computation and selection stage
    shift_selector #(
        .WIDTH(WIDTH)
    ) shift_select_inst (
        .in_data(input_stage_data),
        .one_hot_control(input_stage_control),
        .selected_result(shifter_result)
    );
    
    // Output registration stage
    output_register #(
        .WIDTH(WIDTH)
    ) output_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .selected_result(shifter_result),
        .out_data(out_data)
    );
    
endmodule

// Input registration module
module input_register #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] in_data,
    input wire [WIDTH-1:0] one_hot_control,
    output reg [WIDTH-1:0] reg_data,
    output reg [WIDTH-1:0] reg_control
);
    // Pipeline Stage 1: Register input data and control signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_data <= {WIDTH{1'b0}};
            reg_control <= {WIDTH{1'b0}};
        end else begin
            reg_data <= in_data;
            reg_control <= one_hot_control;
        end
    end
endmodule

// Shift computation and selection module
module shift_selector #(
    parameter WIDTH = 16
)(
    input wire [WIDTH-1:0] in_data,
    input wire [WIDTH-1:0] one_hot_control,
    output wire [WIDTH-1:0] selected_result
);
    // Generate all possible shift options
    wire [WIDTH-1:0] shift_options [0:WIDTH-1];
    
    // Shift generator submodule
    shift_generator #(
        .WIDTH(WIDTH)
    ) shift_gen_inst (
        .in_data(in_data),
        .shift_options(shift_options)
    );
    
    // Shift selector submodule
    priority_selector #(
        .WIDTH(WIDTH)
    ) priority_sel_inst (
        .in_data(in_data),
        .one_hot_control(one_hot_control),
        .shift_options(shift_options),
        .selected_result(selected_result)
    );
endmodule

// Shift options generator module
module shift_generator #(
    parameter WIDTH = 16
)(
    input wire [WIDTH-1:0] in_data,
    output wire [WIDTH-1:0] shift_options [0:WIDTH-1]
);
    // Generate all possible shift combinations
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_shifts
            assign shift_options[i] = in_data << i;
        end
    endgenerate
endmodule

// Priority-based selection module
module priority_selector #(
    parameter WIDTH = 16
)(
    input wire [WIDTH-1:0] in_data,
    input wire [WIDTH-1:0] one_hot_control,
    input wire [WIDTH-1:0] shift_options [0:WIDTH-1],
    output reg [WIDTH-1:0] selected_result
);
    integer i;
    
    // Priority encoder approach to reduce logic depth
    always @(*) begin
        selected_result = in_data; // Default: no shift
        
        for (i = WIDTH-1; i >= 0; i = i - 1) begin
            if (one_hot_control[i])
                selected_result = shift_options[i];
        end
    end
endmodule

// Output registration module
module output_register #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] selected_result,
    output reg [WIDTH-1:0] out_data
);
    // Pipeline Stage 2: Register final output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_data <= {WIDTH{1'b0}};
        end else begin
            out_data <= selected_result;
        end
    end
endmodule