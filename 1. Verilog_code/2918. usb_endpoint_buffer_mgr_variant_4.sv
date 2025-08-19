//SystemVerilog IEEE 1364-2005
module usb_endpoint_buffer_mgr #(
    parameter NUM_ENDPOINTS = 4,
    parameter BUFFER_SIZE = 64,
    parameter ADDR_WIDTH = $clog2(BUFFER_SIZE)
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
    reg [ADDR_WIDTH-1:0] write_ptr [0:NUM_ENDPOINTS-1];
    reg [ADDR_WIDTH-1:0] read_ptr [0:NUM_ENDPOINTS-1];
    reg [7:0] count [0:NUM_ENDPOINTS-1];
    
    // Registered input signals
    reg [3:0] endpoint_select_reg;
    reg write_enable_reg, read_enable_reg;
    reg [7:0] write_data_reg;
    
    // Current endpoint pointer and count
    wire [ADDR_WIDTH-1:0] curr_write_ptr;
    wire [ADDR_WIDTH-1:0] curr_read_ptr;
    wire [7:0] curr_count;
    
    // Optimized pointer calculation
    wire [ADDR_WIDTH-1:0] next_write_ptr;
    wire [ADDR_WIDTH-1:0] next_read_ptr;
    wire [7:0] next_count;
    
    // Enhanced status signals
    wire will_write, will_read;
    wire buffer_at_boundary;
    wire next_buffer_full, next_buffer_empty;
    
    // Register inputs to break timing path
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            endpoint_select_reg <= 4'd0;
            write_enable_reg <= 1'b0;
            read_enable_reg <= 1'b0;
            write_data_reg <= 8'd0;
        end else begin
            endpoint_select_reg <= endpoint_select;
            write_enable_reg <= write_enable;
            read_enable_reg <= read_enable;
            write_data_reg <= write_data;
        end
    end
    
    // Extract current endpoint's state
    assign curr_write_ptr = write_ptr[endpoint_select_reg];
    assign curr_read_ptr = read_ptr[endpoint_select_reg];
    assign curr_count = count[endpoint_select_reg];
    
    // Optimized boundary conditions with more efficient comparisons
    assign buffer_at_boundary = (curr_count == BUFFER_SIZE - 1) || (curr_count == 1);
    
    // Streamlined operation logic with range checks instead of point comparisons
    assign will_write = write_enable_reg && (curr_count < BUFFER_SIZE);
    assign will_read = read_enable_reg && (curr_count > 0);
    
    // Simplified next state calculations using specialized comparators
    assign next_write_ptr = (curr_write_ptr == BUFFER_SIZE-1) ? {ADDR_WIDTH{1'b0}} : curr_write_ptr + 1'b1;
    assign next_read_ptr = (curr_read_ptr == BUFFER_SIZE-1) ? {ADDR_WIDTH{1'b0}} : curr_read_ptr + 1'b1;
    
    // Optimized count calculation with priority encoding
    assign next_count = curr_count + 
                        (will_write ? 8'd1 : 8'd0) - 
                        (will_read ? 8'd1 : 8'd0);
    
    // Enhanced status signals with boundary detection
    assign next_buffer_full = (curr_count == BUFFER_SIZE - 1 && will_write && !will_read) || 
                              (curr_count == BUFFER_SIZE);
    assign next_buffer_empty = (curr_count == 1 && will_read && !will_write) || 
                               (curr_count == 0);
    
    // Main sequential logic with optimized update flow
    integer i;
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            for (i = 0; i < NUM_ENDPOINTS; i = i + 1) begin
                write_ptr[i] <= {ADDR_WIDTH{1'b0}};
                read_ptr[i] <= {ADDR_WIDTH{1'b0}};
                count[i] <= 8'd0;
            end
            buffer_full <= 1'b0;
            buffer_empty <= 1'b1;
            buffer_count <= 8'd0;
            read_data <= 8'd0;
        end else begin
            // Parallel status update for faster timing
            buffer_full <= next_buffer_full;
            buffer_empty <= next_buffer_empty;
            buffer_count <= next_count;
            
            // Prioritized write operation
            if (will_write) begin
                buffers[endpoint_select_reg][curr_write_ptr] <= write_data_reg;
                write_ptr[endpoint_select_reg] <= next_write_ptr;
            end
            
            // Prioritized read operation
            if (will_read) begin
                read_data <= buffers[endpoint_select_reg][curr_read_ptr];
                read_ptr[endpoint_select_reg] <= next_read_ptr;
            end
            
            // Atomic counter update to avoid race conditions
            count[endpoint_select_reg] <= next_count;
        end
    end
endmodule