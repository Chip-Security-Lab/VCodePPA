//SystemVerilog
module priority_demux (
    input wire data_in,                  // Input data
    input wire [2:0] pri_select,         // Priority selection
    output reg [7:0] dout                // Output channels
);
    // Using parameter for better scalability
    parameter DOUT_WIDTH = 8;
    
    // Intermediate signals for better timing
    reg [7:0] output_mask;
    
    always @(*) begin
        // Initialize output mask based on priority select
        case (1'b1)
            pri_select[2]: output_mask = 8'b11110000;
            pri_select[1]: output_mask = 8'b00001100;
            pri_select[0]: output_mask = 8'b00000010;
            default:       output_mask = 8'b00000001;
        endcase
        
        // Data-dependent assignment using conditional operator
        // This implementation can improve timing and reduce logic depth
        dout = data_in ? output_mask : 8'b0;
    end
endmodule