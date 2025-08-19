//SystemVerilog
module buffered_crossbar #(
    parameter WIDTH = 8,
    parameter DEPTH = 2  // Buffer depth as power of 2
)(
    input wire clk, rst_n,
    input wire [(WIDTH*4)-1:0] in_data, // Flattened 4xWIDTH array
    input wire [7:0] out_sel,     // Flattened 4x2 array 
    input wire [3:0] write_en,    // Write enable for input buffers
    input wire [3:0] read_en,     // Read enable for output buffers
    output wire [(WIDTH*4)-1:0] out_data, // Flattened 4xWIDTH array
    output wire [3:0] buf_full, buf_empty
);
    // Input buffers organized as arrays for clearer code
    reg [WIDTH-1:0] buffers [0:3][0:DEPTH-1];
    reg [2:0] count [0:3];
    reg wr_ptr [0:3];
    reg rd_ptr [0:3];
    
    // Buffer status signals
    reg [3:0] buf_full_r, buf_empty_r;
    
    // Manchester carry chain signals for counter increment/decrement
    wire [2:0] count_next [0:3];
    wire [2:0] g_signals [0:3]; // Generate signals
    wire [2:0] p_signals [0:3]; // Propagate signals
    wire [3:0] c_signals [0:3]; // Carry signals (including initial carry-in)
    
    // Determine operation mode for each buffer
    wire [3:0] inc_mode; // Increment mode (1), decrement mode (0)
    wire [3:0] count_update; // Whether to update count
    
    integer i, j;
    
    // Determine operation mode for each counter
    genvar g;
    generate
        for (g = 0; g < 4; g = g + 1) begin : gen_op_mode
            assign inc_mode[g] = write_en[g] && !buf_full_r[g] && !(read_en[g] && !buf_empty_r[g]);
            assign count_update[g] = (write_en[g] && !buf_full_r[g]) || (read_en[g] && !buf_empty_r[g]);
        end
    endgenerate
    
    // Manchester carry chain adder/subtractor implementation for each counter
    generate
        for (g = 0; g < 4; g = g + 1) begin : gen_manchester_adder
            // Generate and propagate signals for Manchester carry chain
            assign g_signals[g][0] = inc_mode[g] ? count[g][0] : ~count[g][0];
            assign g_signals[g][1] = inc_mode[g] ? count[g][1] : ~count[g][1];
            assign g_signals[g][2] = inc_mode[g] ? count[g][2] : ~count[g][2];
            
            assign p_signals[g][0] = 1'b1; // For bit 0, propagate is always 1
            assign p_signals[g][1] = count[g][0];
            assign p_signals[g][2] = count[g][1] & count[g][0];
            
            // Carry chain
            assign c_signals[g][0] = inc_mode[g] ? 1'b1 : 1'b1; // Initial carry-in (1 for both inc and dec)
            assign c_signals[g][1] = g_signals[g][0] | (p_signals[g][0] & c_signals[g][0]);
            assign c_signals[g][2] = g_signals[g][1] | (p_signals[g][1] & c_signals[g][1]);
            assign c_signals[g][3] = g_signals[g][2] | (p_signals[g][2] & c_signals[g][2]);
            
            // Sum bits
            assign count_next[g][0] = count[g][0] ^ c_signals[g][0];
            assign count_next[g][1] = count[g][1] ^ c_signals[g][1];
            assign count_next[g][2] = count[g][2] ^ c_signals[g][2];
        end
    endgenerate
    
    // Buffer management logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 4; i = i + 1) begin
                count[i] <= 0;
                wr_ptr[i] <= 0;
                rd_ptr[i] <= 0;
                buf_full_r[i] <= 0;
                buf_empty_r[i] <= 1; // Empty initially
                for (j = 0; j < DEPTH; j = j + 1) begin
                    buffers[i][j] <= 0;
                end
            end
        end else begin
            for (i = 0; i < 4; i = i + 1) begin
                // Update full/empty flags
                buf_full_r[i] <= (count[i] == DEPTH);
                buf_empty_r[i] <= (count[i] == 0);
                
                // Write to buffer
                if (write_en[i] && !buf_full_r[i]) begin
                    // Extract correct slice from input data based on selector
                    buffers[i][wr_ptr[i]] <= in_data[(out_sel[i*2+:2]*WIDTH) +: WIDTH];
                    wr_ptr[i] <= wr_ptr[i] + 1;
                    
                    // Count updated using Manchester carry chain
                    if (!(read_en[i] && !buf_empty_r[i])) begin
                        count[i] <= count_next[i];
                    end
                end
                
                // Read from buffer
                if (read_en[i] && !buf_empty_r[i]) begin
                    rd_ptr[i] <= rd_ptr[i] + 1;
                    
                    // Count updated using Manchester carry chain
                    if (!(write_en[i] && !buf_full_r[i])) begin
                        count[i] <= count_next[i];
                    end
                end
                
                // Handle simultaneous read and write - count remains the same
                if (write_en[i] && !buf_full_r[i] && read_en[i] && !buf_empty_r[i]) begin
                    count[i] <= count[i]; // No change in count
                end
            end
        end
    end
    
    // Output assignments
    generate 
        for (g = 0; g < 4; g = g + 1) begin : gen_outputs
            assign buf_full[g] = buf_full_r[g];
            assign buf_empty[g] = buf_empty_r[g];
            assign out_data[(g*WIDTH) +: WIDTH] = buffers[g][rd_ptr[g]];
        end
    endgenerate
endmodule