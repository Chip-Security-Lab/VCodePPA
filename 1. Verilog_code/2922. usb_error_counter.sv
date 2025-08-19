module usb_error_counter(
    input wire clk,
    input wire rst_n,
    input wire crc_error,
    input wire pid_error,
    input wire timeout_error,
    input wire bitstuff_error,
    input wire babble_detected,
    input wire clear_counters,
    output reg [7:0] crc_error_count,
    output reg [7:0] pid_error_count,
    output reg [7:0] timeout_error_count,
    output reg [7:0] bitstuff_error_count,
    output reg [7:0] babble_error_count,
    output reg [1:0] error_status
);
    localparam NO_ERRORS = 2'b00;
    localparam WARNING = 2'b01;
    localparam CRITICAL = 2'b10;
    
    reg any_error_detected;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_error_count <= 8'd0;
            pid_error_count <= 8'd0;
            timeout_error_count <= 8'd0;
            bitstuff_error_count <= 8'd0;
            babble_error_count <= 8'd0;
            error_status <= NO_ERRORS;
            any_error_detected <= 1'b0;
        end else if (clear_counters) begin
            crc_error_count <= 8'd0;
            pid_error_count <= 8'd0;
            timeout_error_count <= 8'd0;
            bitstuff_error_count <= 8'd0;
            babble_error_count <= 8'd0;
            error_status <= NO_ERRORS;
        end else begin
            any_error_detected <= crc_error || pid_error || timeout_error || 
                                 bitstuff_error || babble_detected;
            
            if (crc_error && crc_error_count < 8'hFF)
                crc_error_count <= crc_error_count + 8'd1;
                
            if (pid_error && pid_error_count < 8'hFF)
                pid_error_count <= pid_error_count + 8'd1;
                
            if (timeout_error && timeout_error_count < 8'hFF)
                timeout_error_count <= timeout_error_count + 8'd1;
                
            if (bitstuff_error && bitstuff_error_count < 8'hFF)
                bitstuff_error_count <= bitstuff_error_count + 8'd1;
                
            if (babble_detected && babble_error_count < 8'hFF)
                babble_error_count <= babble_error_count + 8'd1;
                
            // Update error status
            if (babble_error_count > 8'd3 || timeout_error_count > 8'd10)
                error_status <= CRITICAL;
            else if (any_error_detected)
                error_status <= WARNING;
        end
    end
endmodule