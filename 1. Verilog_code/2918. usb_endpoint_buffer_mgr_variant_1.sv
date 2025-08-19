//SystemVerilog
module usb_endpoint_buffer_mgr #(
    parameter NUM_ENDPOINTS = 4,
    parameter BUFFER_SIZE = 64,
    parameter PTR_WIDTH = $clog2(BUFFER_SIZE)
)(
    input wire clk,
    input wire rst_b,
    input wire [3:0] endpoint_select,
    input wire write_enable,
    input wire read_enable,
    input wire [7:0] write_data,
    output reg [7:0] read_data,
    output wire buffer_full,
    output wire buffer_empty,
    output wire [7:0] buffer_count
);
    // RAM for each endpoint buffer
    reg [7:0] buffers [0:NUM_ENDPOINTS-1][0:BUFFER_SIZE-1];
    
    // Pointers and counters for each endpoint - using minimum required bit width
    reg [PTR_WIDTH-1:0] write_ptr [0:NUM_ENDPOINTS-1];
    reg [PTR_WIDTH-1:0] read_ptr [0:NUM_ENDPOINTS-1];
    reg [7:0] count [0:NUM_ENDPOINTS-1];
    
    // Current endpoint's pointers - registered for better timing
    reg [3:0] endpoint_select_r;
    reg [PTR_WIDTH-1:0] curr_write_ptr;
    reg [PTR_WIDTH-1:0] curr_read_ptr;
    reg [7:0] curr_count;
    
    // Pre-compute next pointer values
    wire [PTR_WIDTH-1:0] next_write_ptr = (curr_write_ptr == BUFFER_SIZE-1) ? {PTR_WIDTH{1'b0}} : curr_write_ptr + 1'b1;
    wire [PTR_WIDTH-1:0] next_read_ptr = (curr_read_ptr == BUFFER_SIZE-1) ? {PTR_WIDTH{1'b0}} : curr_read_ptr + 1'b1;
    
    // Status signals for control logic
    wire can_write = write_enable && !buffer_full;
    wire can_read = read_enable && !buffer_empty;
    
    // Status outputs
    assign buffer_full = (curr_count == BUFFER_SIZE);
    assign buffer_empty = (curr_count == 8'd0);
    assign buffer_count = curr_count;
    
    // Reset logic in separate always block
    integer i;
    always @(negedge rst_b) begin
        if (!rst_b) begin
            for (i = 0; i < NUM_ENDPOINTS; i = i + 1) begin
                write_ptr[i] <= {PTR_WIDTH{1'b0}};
                read_ptr[i] <= {PTR_WIDTH{1'b0}};
                count[i] <= 8'd0;
            end
            endpoint_select_r <= 4'd0;
            curr_write_ptr <= {PTR_WIDTH{1'b0}};
            curr_read_ptr <= {PTR_WIDTH{1'b0}};
            curr_count <= 8'd0;
        end
    end
    
    // Register endpoint selection and update current pointers
    always @(posedge clk) begin
        if (rst_b) begin
            endpoint_select_r <= endpoint_select;
            curr_write_ptr <= write_ptr[endpoint_select];
            curr_read_ptr <= read_ptr[endpoint_select];
            curr_count <= count[endpoint_select];
        end
    end
    
    // Handle write operations
    always @(posedge clk) begin
        if (rst_b && can_write) begin
            buffers[endpoint_select_r][curr_write_ptr] <= write_data;
            write_ptr[endpoint_select_r] <= next_write_ptr;
        end
    end
    
    // Handle read operations
    always @(posedge clk) begin
        if (rst_b && can_read) begin
            read_data <= buffers[endpoint_select_r][curr_read_ptr];
            read_ptr[endpoint_select_r] <= next_read_ptr;
        end
    end
    
    // Update count based on operations
    always @(posedge clk) begin
        if (rst_b) begin
            case ({can_write, can_read})
                2'b10: count[endpoint_select_r] <= curr_count + 8'd1;
                2'b01: count[endpoint_select_r] <= curr_count - 8'd1;
                2'b11: count[endpoint_select_r] <= curr_count; // Simultaneous read/write, count unchanged
                default: count[endpoint_select_r] <= curr_count;
            endcase
        end
    end
endmodule