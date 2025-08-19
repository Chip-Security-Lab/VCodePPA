//SystemVerilog
module sync_buffer_async_rst (
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    input wire valid_in,
    output wire ready_out,
    output reg [7:0] data_out
);

    reg data_received;
    reg valid_in_delayed; // Single delayed valid signal
    reg ready_int;        // Internal ready signal
    
    // Directly register the input data when valid (moved forward)
    // This eliminates the separate data_in_reg and reduces input-to-register delay
    always @(posedge clk) begin
        if (valid_in && ready_int) begin
            data_out <= data_in;
        end
    end
    
    // Buffer the valid_in signal - reduced from two to one stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_in_delayed <= 1'b0;
        end else begin
            valid_in_delayed <= valid_in;
        end
    end
    
    // Generate ready signal - using the valid_in directly where timing permits
    assign ready_out = ready_int;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready_int <= 1'b1;
            data_received <= 1'b0;
        end else begin
            ready_int <= !data_received || valid_in;
            
            if (valid_in_delayed && ready_int) begin
                data_received <= 1'b1;
            end else if (!valid_in_delayed) begin
                data_received <= 1'b0;
            end
        end
    end
    
endmodule