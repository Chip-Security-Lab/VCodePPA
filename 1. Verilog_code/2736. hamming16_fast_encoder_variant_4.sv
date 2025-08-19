//SystemVerilog
module hamming16_fast_encoder(
    input wire clk,
    input wire rst_n,
    input wire [15:0] raw_data,
    output reg [21:0] encoded_data
);

    // Stage 1: Data Input and Initial Processing with reduced fanout
    reg [15:0] raw_data_reg;
    // Buffer registers for high fanout raw_data_reg signal
    reg [15:0] raw_data_reg_buf1, raw_data_reg_buf2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            raw_data_reg <= 16'b0;
            raw_data_reg_buf1 <= 16'b0;
            raw_data_reg_buf2 <= 16'b0;
        end else begin
            raw_data_reg <= raw_data;
            raw_data_reg_buf1 <= raw_data_reg;
            raw_data_reg_buf2 <= raw_data_reg;
        end
    end

    // Stage 2: Parity Calculation
    reg [4:0] parity_reg;
    wire [4:0] parity_next;
    // Buffer for parity_next high fanout signal
    reg [3:0] parity_next_buf;
    
    // Parallel parity calculation with pipelined structure
    // Using balanced loads with buffered raw_data_reg
    assign parity_next[0] = ^(raw_data_reg_buf1 & 16'b1010_1010_1010_1010);
    assign parity_next[1] = ^(raw_data_reg_buf1 & 16'b1100_1100_1100_1100);
    assign parity_next[2] = ^(raw_data_reg_buf2 & 16'b1111_0000_1111_0000);
    assign parity_next[3] = ^(raw_data_reg_buf2 & 16'b1111_1111_0000_0000);
    
    // Buffer for high fanout parity_next[3:0]
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parity_next_buf <= 4'b0;
        end else begin
            parity_next_buf <= parity_next[3:0];
        end
    end
    
    // Using buffered signals for overall parity calculation
    assign parity_next[4] = ^{parity_next_buf, raw_data_reg_buf1};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parity_reg <= 5'b0;
        end else begin
            parity_reg <= parity_next;
        end
    end

    // Buffer registers for high fanout parity_reg signal
    reg [4:0] parity_reg_buf;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parity_reg_buf <= 5'b0;
        end else begin
            parity_reg_buf <= parity_reg;
        end
    end

    // Stage 3: Output Assembly with buffered signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            encoded_data <= 22'b0;
        end else begin
            encoded_data <= {
                raw_data_reg_buf2[15:11], parity_reg_buf[3],
                raw_data_reg_buf2[10:4], parity_reg_buf[2],
                raw_data_reg_buf2[3:1], parity_reg_buf[1],
                raw_data_reg_buf2[0], parity_reg_buf[0], parity_reg_buf[4]
            };
        end
    end

endmodule