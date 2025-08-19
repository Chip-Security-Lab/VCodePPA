module noise_filter_recovery #(
    parameter WIDTH = 10,
    parameter FILTER_DEPTH = 3
)(
    input wire clk,
    input wire enable,
    input wire [WIDTH-1:0] noisy_data,
    output reg [WIDTH-1:0] clean_data,
    output reg data_valid
);
    reg [WIDTH-1:0] history [0:FILTER_DEPTH-1];
    reg [WIDTH-1:0] sorted [0:FILTER_DEPTH-1];
    integer i, j;
    reg [WIDTH-1:0] temp;
    
    always @(posedge clk) begin
        if (enable) begin
            // Shift history
            for (i = FILTER_DEPTH-1; i > 0; i = i - 1)
                history[i] <= history[i-1];
            history[0] <= noisy_data;
            
            // Copy to sorting array
            for (i = 0; i < FILTER_DEPTH; i = i + 1)
                sorted[i] <= history[i];
                
            // Bubble sort for median filtering
            for (i = 0; i < FILTER_DEPTH-1; i = i + 1)
                for (j = 0; j < FILTER_DEPTH-i-1; j = j + 1)
                    if (sorted[j] > sorted[j+1]) begin
                        temp = sorted[j];
                        sorted[j] = sorted[j+1];
                        sorted[j+1] = temp;
                    end
                    
            // Output median value
            clean_data <= sorted[FILTER_DEPTH/2];
            data_valid <= 1'b1;
        end else begin
            data_valid <= 1'b0;
        end
    end
endmodule