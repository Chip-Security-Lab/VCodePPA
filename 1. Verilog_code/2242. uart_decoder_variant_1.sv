//SystemVerilog
module uart_decoder #(parameter BAUD_RATE=9600) (
    input  wire       rx, clk,
    output reg  [7:0] data,
    output reg        parity_err
);
    // Use one-hot state encoding for sample counter
    reg [15:0] sample_state;
    wire mid_sample = sample_state[7];
    
    // Input registering
    reg rx_pipe;
    
    // Optimized data pipeline and parity calculation
    reg [7:0] data_pipe;
    reg parity_calc_stage1;
    
    // Initialize state
    initial sample_state = 16'h0001;
    
    always @(posedge clk) begin
        // Input registration stage - maintain timing
        rx_pipe <= rx;
        
        // Counter logic with one-hot encoding for better timing
        if(rx) begin
            if(|sample_state[14:0])
                sample_state <= {sample_state[14:0], sample_state[15]};
        end else begin
            sample_state <= 16'h0001;
        end
            
        // First pipeline stage - calculate partial parity
        // Use mid_sample instead of comparison
        if(mid_sample) begin
            data_pipe <= {rx_pipe, data_pipe[7:1]};
            // XOR reduction operator for more efficient parity calculation
            parity_calc_stage1 <= ^{data[7:0]};
        end
        
        // Second pipeline stage - complete the operation with mid_sample signal
        if(mid_sample) begin
            data <= data_pipe;
            // Simplified parity error checking
            parity_err <= parity_calc_stage1 ^ rx_pipe;
        end
    end
endmodule