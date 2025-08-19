module usb_endpoint_buffer_mgr #(
    parameter NUM_ENDPOINTS = 4,
    parameter BUFFER_SIZE = 64
)(
    input wire clk,
    input wire rst_b,
    input wire [3:0] endpoint_select,
    input wire write_enable,
    input wire read_enable,
    input wire [7:0] write_data,
    output reg [7:0] read_data,
    output reg buffer_full,
    output reg buffer_empty,
    output reg [7:0] buffer_count
);
    // RAM for each endpoint buffer
    reg [7:0] buffers [0:NUM_ENDPOINTS-1][0:BUFFER_SIZE-1];
    
    // Pointers and counters for each endpoint
    reg [7:0] write_ptr [0:NUM_ENDPOINTS-1];
    reg [7:0] read_ptr [0:NUM_ENDPOINTS-1];
    reg [7:0] count [0:NUM_ENDPOINTS-1];
    
    // Current endpoint's pointers
    wire [7:0] curr_write_ptr = write_ptr[endpoint_select];
    wire [7:0] curr_read_ptr = read_ptr[endpoint_select];
    wire [7:0] curr_count = count[endpoint_select];
    
    integer i;
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            for (i = 0; i < NUM_ENDPOINTS; i = i + 1) begin
                write_ptr[i] <= 8'd0;
                read_ptr[i] <= 8'd0;
                count[i] <= 8'd0;
            end
            buffer_full <= 1'b0;
            buffer_empty <= 1'b1;
            buffer_count <= 8'd0;
        end else begin
            // Update status flags for currently selected endpoint
            buffer_full <= (curr_count == BUFFER_SIZE);
            buffer_empty <= (curr_count == 8'd0);
            buffer_count <= curr_count;
            
            // Process write request
            if (write_enable && !buffer_full) begin
                buffers[endpoint_select][curr_write_ptr] <= write_data;
                write_ptr[endpoint_select] <= (curr_write_ptr + 8'd1) % BUFFER_SIZE;
                count[endpoint_select] <= curr_count + 8'd1;
            end
            
            // Process read request
            if (read_enable && !buffer_empty) begin
                read_data <= buffers[endpoint_select][curr_read_ptr];
                read_ptr[endpoint_select] <= (curr_read_ptr + 8'd1) % BUFFER_SIZE;
                count[endpoint_select] <= curr_count - 8'd1;
            end
        end
    end
endmodule