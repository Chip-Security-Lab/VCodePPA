//SystemVerilog
module watchdog_buf #(
    parameter DW      = 8,
    parameter TIMEOUT = 1000
) (
    input              clk,
    input              rst_n,
    input              wr_en,
    input              rd_en,
    input  [DW-1:0]    din,
    output [DW-1:0]    dout,
    output             error
);
    // Internal signals for module interconnection
    wire             valid;
    wire             timeout_detected;
    wire [DW-1:0]    buf_data;
    wire             reset_timeout;
    
    // Data buffer management submodule instance
    data_buffer #(
        .DW(DW)
    ) u_data_buffer (
        .clk             (clk),
        .rst_n           (rst_n),
        .wr_en           (wr_en),
        .rd_en           (rd_en),
        .din             (din),
        .dout            (dout),
        .buf_data        (buf_data),
        .valid           (valid),
        .timeout_detected(timeout_detected),
        .reset_timeout   (reset_timeout)
    );
    
    // Timeout monitoring submodule instance
    timeout_monitor #(
        .TIMEOUT(TIMEOUT)
    ) u_timeout_monitor (
        .clk             (clk),
        .rst_n           (rst_n),
        .wr_en           (wr_en),
        .rd_en           (rd_en),
        .valid           (valid),
        .timeout_detected(timeout_detected),
        .reset_timeout   (reset_timeout),
        .error           (error)
    );
    
endmodule

module data_buffer #(
    parameter DW = 8
) (
    input               clk,
    input               rst_n,
    input               wr_en,
    input               rd_en,
    input  [DW-1:0]     din,
    output reg [DW-1:0] dout,
    output reg [DW-1:0] buf_data,
    output reg          valid,
    input               timeout_detected,
    output              reset_timeout
);
    // Reset timeout flag when data is written or read
    assign reset_timeout = wr_en | (rd_en & valid);
    
    // Buffer data management
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid <= 1'b0;
            buf_data <= {DW{1'b0}};
            dout <= {DW{1'b0}};
        end
        else begin
            // Prioritize write operation
            if (wr_en) begin
                buf_data <= din;
                valid <= 1'b1;
            end
            else if (timeout_detected) begin
                valid <= 1'b0;
            end
            else if (rd_en && valid) begin
                dout <= buf_data;
                valid <= 1'b0;
            end
        end
    end
endmodule

module timeout_monitor #(
    parameter TIMEOUT = 1000
) (
    input        clk,
    input        rst_n,
    input        wr_en,
    input        rd_en,
    input        valid,
    output       timeout_detected,
    input        reset_timeout,
    output reg   error
);
    // Use smaller counter when possible
    localparam COUNTER_WIDTH = $clog2(TIMEOUT+1);
    reg [COUNTER_WIDTH-1:0] counter;
    
    // Optimized comparison for timeout detection
    assign timeout_detected = (counter == TIMEOUT);
    
    // Timeout counter management - optimized state transitions
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= {COUNTER_WIDTH{1'b0}};
            error <= 1'b0;
        end
        else begin
            if (reset_timeout) begin
                counter <= {COUNTER_WIDTH{1'b0}};
                error <= 1'b0;
            end
            else if (valid) begin
                // Set error flag when timeout occurs and keep it set
                if (timeout_detected) begin
                    error <= 1'b1;
                end
                // Only increment counter if not at timeout value
                else begin
                    counter <= counter + 1'b1;
                end
            end
        end
    end
endmodule