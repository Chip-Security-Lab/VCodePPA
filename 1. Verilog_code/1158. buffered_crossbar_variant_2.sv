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
    // Stage 1: Input registration and selector decoding
    reg [(WIDTH*4)-1:0] in_data_stage1;
    reg [7:0] out_sel_stage1;
    reg [3:0] write_en_stage1, read_en_stage1;
    
    // Extract selector values for easier access
    wire [1:0] port_sel_stage1 [0:3];
    
    genvar s;
    generate
        for (s = 0; s < 4; s = s + 1) begin : sel_decode
            assign port_sel_stage1[s] = out_sel_stage1[s*2+:2];
        end
    endgenerate
    
    // Stage 1 to Stage 2 pipeline registers
    reg [(WIDTH*4)-1:0] in_data_stage2;
    reg [3:0][1:0] port_sel_stage2;
    reg [3:0] write_en_stage2, read_en_stage2;
    reg stage1_valid;
    
    // Stage 2: Data selection and preparation
    wire [WIDTH-1:0] selected_data_stage2 [0:3];
    
    generate
        for (s = 0; s < 4; s = s + 1) begin : data_select
            assign selected_data_stage2[s] = in_data_stage2[(port_sel_stage2[s]*WIDTH) +: WIDTH];
        end
    endgenerate
    
    // Stage 2 to Stage 3 pipeline registers
    reg [3:0][WIDTH-1:0] selected_data_stage3;
    reg [3:0] write_en_stage3, read_en_stage3;
    reg stage2_valid;
    
    // Stage 3: Buffer storage and management
    reg [WIDTH-1:0] buffers [0:3][0:DEPTH-1];
    reg [2:0] count [0:3];
    reg wr_ptr [0:3];
    reg rd_ptr [0:3];
    reg [3:0] buf_full_r, buf_empty_r;
    reg stage3_valid;
    
    // Output stage signals
    reg [3:0][WIDTH-1:0] out_data_r;
    reg [3:0] buf_full_out, buf_empty_out;
    
    integer i, j;
    
    // Stage 1: Register input signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_data_stage1 <= {(WIDTH*4){1'b0}};
            out_sel_stage1 <= 8'b0;
            write_en_stage1 <= 4'b0;
            read_en_stage1 <= 4'b0;
            stage1_valid <= 1'b0;
        end else begin
            in_data_stage1 <= in_data;
            out_sel_stage1 <= out_sel;
            write_en_stage1 <= write_en;
            read_en_stage1 <= read_en;
            stage1_valid <= 1'b1;
        end
    end
    
    // Pipeline Stage 1 to Stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_data_stage2 <= {(WIDTH*4){1'b0}};
            for (i = 0; i < 4; i = i + 1) begin
                port_sel_stage2[i] <= 2'b00;
            end
            write_en_stage2 <= 4'b0;
            read_en_stage2 <= 4'b0;
            stage2_valid <= 1'b0;
        end else if (stage1_valid) begin
            in_data_stage2 <= in_data_stage1;
            for (i = 0; i < 4; i = i + 1) begin
                port_sel_stage2[i] <= port_sel_stage1[i];
            end
            write_en_stage2 <= write_en_stage1;
            read_en_stage2 <= read_en_stage1;
            stage2_valid <= stage1_valid;
        end
    end
    
    // Pipeline Stage 2 to Stage 3
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 4; i = i + 1) begin
                selected_data_stage3[i] <= {WIDTH{1'b0}};
            end
            write_en_stage3 <= 4'b0;
            read_en_stage3 <= 4'b0;
            stage3_valid <= 1'b0;
        end else if (stage2_valid) begin
            for (i = 0; i < 4; i = i + 1) begin
                selected_data_stage3[i] <= selected_data_stage2[i];
            end
            write_en_stage3 <= write_en_stage2;
            read_en_stage3 <= read_en_stage2;
            stage3_valid <= stage2_valid;
        end
    end
    
    // Stage 3: Buffer management logic
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
                out_data_r[i] <= {WIDTH{1'b0}};
            end
            buf_full_out <= 4'b0;
            buf_empty_out <= 4'b1111;
        end else begin
            // Update status signals for output
            buf_full_out <= buf_full_r;
            buf_empty_out <= buf_empty_r;
            
            for (i = 0; i < 4; i = i + 1) begin
                // Update full/empty flags
                buf_full_r[i] <= (count[i] == DEPTH);
                buf_empty_r[i] <= (count[i] == 0);
                
                // Prepare output data
                out_data_r[i] <= buffers[i][rd_ptr[i]];
                
                // Process based on valid stage3 data
                if (stage3_valid) begin
                    // Write to buffer using selected data from stage3
                    if (write_en_stage3[i] && !buf_full_r[i]) begin
                        buffers[i][wr_ptr[i]] <= selected_data_stage3[i];
                        wr_ptr[i] <= wr_ptr[i] + 1;
                        count[i] <= count[i] + 1;
                    end
                    
                    // Read from buffer
                    if (read_en_stage3[i] && !buf_empty_r[i]) begin
                        rd_ptr[i] <= rd_ptr[i] + 1;
                        count[i] <= count[i] - 1;
                    end
                end
            end
        end
    end
    
    // Output assignments
    genvar g;
    generate 
        for (g = 0; g < 4; g = g + 1) begin : gen_outputs
            assign buf_full[g] = buf_full_out[g];
            assign buf_empty[g] = buf_empty_out[g];
            assign out_data[(g*WIDTH) +: WIDTH] = out_data_r[g];
        end
    endgenerate
endmodule