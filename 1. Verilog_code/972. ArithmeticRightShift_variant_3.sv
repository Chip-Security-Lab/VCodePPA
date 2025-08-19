//SystemVerilog
module ArithmeticRightShift #(
    parameter WIDTH = 8
) (
    input wire                  clk,         // Clock input
    input wire                  rst_n,       // Active low reset
    input wire                  valid_in,    // Input data valid signal
    input wire [WIDTH-1:0]      data_in,     // Input data to be shifted
    input wire [4:0]            shift_amount, // Shift amount (0-31 bits)
    output reg                  valid_out,   // Output data valid signal
    output reg [WIDTH-1:0]      data_out     // Shifted output data
);

    // Pipeline stage 1 registers
    reg [WIDTH-1:0]         data_stage1;
    reg [4:0]               shift_amount_stage1;
    reg                     valid_stage1;
    
    // Pipeline stage 2 registers
    reg [WIDTH-1:0]         data_stage2;
    reg [4:0]               shift_amount_stage2;
    reg                     valid_stage2;
    
    // Sign bit for extensions
    reg                     sign_bit_stage2;
    
    // First pipeline stage - register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= {WIDTH{1'b0}};
            shift_amount_stage1 <= 5'b0;
            valid_stage1 <= 1'b0;
        end else begin
            data_stage1 <= data_in;
            shift_amount_stage1 <= shift_amount;
            valid_stage1 <= valid_in;
        end
    end
    
    // Second pipeline stage - prepare shift operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= {WIDTH{1'b0}};
            shift_amount_stage2 <= 5'b0;
            valid_stage2 <= 1'b0;
            sign_bit_stage2 <= 1'b0;
        end else begin
            data_stage2 <= data_stage1;
            shift_amount_stage2 <= shift_amount_stage1;
            valid_stage2 <= valid_stage1;
            sign_bit_stage2 <= data_stage1[WIDTH-1];
        end
    end
    
    // Final pipeline stage - perform the arithmetic right shift
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_stage2;
            
            // Optimized range-based implementation
            if (shift_amount_stage2 >= WIDTH) begin
                // If shift amount exceeds or equals data width, fill with sign bit
                data_out <= {WIDTH{sign_bit_stage2}};
            end
            else if (shift_amount_stage2 == 0) begin
                // No shift needed
                data_out <= data_stage2;
            end
            else begin
                // Use a more efficient parameterized approach for shifting
                // Pre-calculate sign extension bits and shifted data separately
                data_out <= {{WIDTH{sign_bit_stage2}} >> (WIDTH-shift_amount_stage2), 
                            data_stage2[WIDTH-1:0] >> shift_amount_stage2};
            end
        end
    end

endmodule