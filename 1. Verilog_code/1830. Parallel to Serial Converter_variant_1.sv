//SystemVerilog
module parallel2serial #(parameter DATA_WIDTH = 8) (
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  valid_in,
    input  wire [DATA_WIDTH-1:0] parallel_data,
    output wire                  ready,
    output reg                   serial_out,
    output wire                  valid_out
);
    // Pre-registered input data to reduce input-to-register delay
    reg [DATA_WIDTH-1:0] data_reg;
    reg valid_in_reg;
    
    // Main processing registers
    reg [DATA_WIDTH-2:0] shift_reg;  // Reduced by 1 bit
    reg [$clog2(DATA_WIDTH):0] bit_count;
    reg busy;
    
    // Control signals
    assign ready = ~busy;
    assign valid_out = (bit_count > 0);
    
    // Input registration stage
    always @(posedge clk) begin
        if (rst) begin
            data_reg <= 0;
            valid_in_reg <= 0;
        end else begin
            data_reg <= parallel_data;
            valid_in_reg <= valid_in;
        end
    end
    
    // Main processing logic with retimed registers
    always @(posedge clk) begin
        if (rst) begin
            shift_reg <= 0;
            bit_count <= 0;
            serial_out <= 0;
            busy <= 0;
        end else if (valid_in_reg && ready) begin
            // Load data into shift register and set MSB directly to output
            serial_out <= data_reg[DATA_WIDTH-1];
            shift_reg <= data_reg[DATA_WIDTH-2:0];
            bit_count <= DATA_WIDTH;
            busy <= 1;
        end else if (bit_count > 1) begin
            // Continue shifting data
            serial_out <= shift_reg[DATA_WIDTH-2];
            shift_reg <= {shift_reg[DATA_WIDTH-3:0], 1'b0};
            bit_count <= bit_count - 1;
            if (bit_count == 2) busy <= 0;
        end else if (bit_count == 1) begin
            // Last bit case
            bit_count <= 0;
            serial_out <= 0;
        end
    end
endmodule