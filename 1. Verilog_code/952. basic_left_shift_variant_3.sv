//SystemVerilog
module basic_left_shift #(parameter DATA_WIDTH = 8) (
    input  wire clk_i,
    input  wire rst_i,
    input  wire si,        // Serial input
    output wire so         // Serial output
);
    // Stage registers for improved data flow and timing
    reg [DATA_WIDTH-1:0] shift_register;
    
    // Pipeline register for serial output (improves timing)
    reg serial_out_reg;
    
    // Main shift register operation with clear data flow path
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            shift_register <= {DATA_WIDTH{1'b0}};
        end else begin
            // Explicit data flow: shift left and insert new bit
            shift_register <= {shift_register[DATA_WIDTH-2:0], si};
        end
    end
    
    // Output stage with registered output for better timing
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            serial_out_reg <= 1'b0;
        end else begin
            serial_out_reg <= shift_register[DATA_WIDTH-1];
        end
    end
    
    // Clean output assignment
    assign so = serial_out_reg;
endmodule