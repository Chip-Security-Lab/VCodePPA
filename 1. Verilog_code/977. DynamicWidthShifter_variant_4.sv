//SystemVerilog
// Top level module
module DynamicWidthShifter #(
    parameter MAX_WIDTH = 16
)(
    input  wire        clk,
    input  wire        rst_n,         // Added reset signal
    input  wire [4:0]  current_width,
    input  wire        serial_in,
    input  wire        valid_in,      // Input valid signal
    output wire        ready_in,      // Ready to accept input
    output wire        serial_out,
    output wire        valid_out      // Output valid signal
);

    // Pipeline stage signals
    wire [MAX_WIDTH-1:0] shift_buffer;
    wire                 stage1_valid;
    wire [4:0]           current_width_stage1;
    wire [MAX_WIDTH-1:0] shift_data_stage1;
    
    // Ready signals for backpressure
    wire stage1_ready;
    
    // Stage ready signal connections
    assign ready_in = stage1_ready;
    assign stage1_ready = 1'b1; // Always ready in this implementation
    
    // Instantiate the input shift register module (stage 0)
    InputShiftRegister #(
        .WIDTH(MAX_WIDTH)
    ) input_shift_inst (
        .clk           (clk),
        .rst_n         (rst_n),
        .serial_in     (serial_in),
        .valid_in      (valid_in),
        .ready_out     (ready_in),
        .shift_data    (shift_buffer),
        .valid_out     (stage1_valid),
        .current_width_in  (current_width),
        .current_width_out (current_width_stage1)
    );

    // Instantiate the output selector module (stage 1)
    OutputSelector #(
        .MAX_WIDTH(MAX_WIDTH)
    ) output_sel_inst (
        .clk           (clk),
        .rst_n         (rst_n),
        .valid_in      (stage1_valid),
        .ready_in      (stage1_ready),
        .current_width (current_width_stage1),
        .shift_data    (shift_buffer),
        .shift_data_reg(shift_data_stage1),
        .serial_out    (serial_out),
        .valid_out     (valid_out)
    );

endmodule

// Module to handle the input shifting operation
module InputShiftRegister #(
    parameter WIDTH = 16
)(
    input  wire              clk,
    input  wire              rst_n,
    input  wire              serial_in,
    input  wire              valid_in,
    input  wire              ready_out,
    input  wire [4:0]        current_width_in,
    output reg [WIDTH-1:0]   shift_data,
    output reg               valid_out,
    output reg [4:0]         current_width_out
);

    // Pipeline stage 0 - input shift register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_data <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
            current_width_out <= 5'd0;
        end else if (ready_out) begin
            if (valid_in) begin
                shift_data <= {shift_data[WIDTH-2:0], serial_in};
                valid_out <= 1'b1;
                current_width_out <= current_width_in;
            end else begin
                valid_out <= 1'b0;
            end
        end
    end

endmodule

// Module to select the output bit based on current_width
module OutputSelector #(
    parameter MAX_WIDTH = 16
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 valid_in,
    input  wire                 ready_in,
    input  wire [4:0]           current_width,
    input  wire [MAX_WIDTH-1:0] shift_data,
    output reg [MAX_WIDTH-1:0]  shift_data_reg,
    output reg                  serial_out,
    output reg                  valid_out
);

    // Pipeline registers for stage 1
    reg [4:0] current_width_reg;
    
    // Pipeline stage 1 - output selection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_data_reg <= {MAX_WIDTH{1'b0}};
            current_width_reg <= 5'd0;
            serial_out <= 1'b0;
            valid_out <= 1'b0;
        end else if (ready_in) begin
            if (valid_in) begin
                // Register shift data for better timing
                shift_data_reg <= shift_data;
                current_width_reg <= current_width;
                
                // Select the output bit based on current width
                serial_out <= shift_data[current_width-1];
                valid_out <= 1'b1;
            end else begin
                valid_out <= 1'b0;
            end
        end
    end

endmodule