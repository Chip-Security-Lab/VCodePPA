//SystemVerilog
module shared_line_ismu(
    input wire clock, resetn,
    input wire [3:0] device_interrupts,
    input wire [7:0] line_assignment, // 2-bit per device
    output reg [1:0] irq_lines
);
    // Intermediate signals for line processing
    reg [1:0] device_lines [0:3];
    reg [1:0] line_status;
    
    // Buffered copies of high fanout signals
    reg [3:0] device_interrupts_buf1, device_interrupts_buf2;
    reg [7:0] line_assignment_buf1, line_assignment_buf2;
    reg [1:0] line_status_buf1, line_status_buf2;
    
    // Counter with buffers to reduce fanout
    integer i;
    reg [1:0] i_buf1, i_buf2;
    
    // Input buffering stage for high fanout inputs
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            device_interrupts_buf1 <= 4'b0000;
            device_interrupts_buf2 <= 4'b0000;
            line_assignment_buf1 <= 8'b00000000;
            line_assignment_buf2 <= 8'b00000000;
        end else begin
            device_interrupts_buf1 <= device_interrupts;
            device_interrupts_buf2 <= device_interrupts;
            line_assignment_buf1 <= line_assignment;
            line_assignment_buf2 <= line_assignment;
        end
    end
    
    // Extract device line assignments with buffered inputs
    always @(*) begin
        for (i = 0; i < 4; i = i + 1) begin
            i_buf1 = i; // Buffer the loop counter
            device_lines[i_buf1][0] = line_assignment_buf1[i_buf1*2];
            device_lines[i_buf1][1] = line_assignment_buf1[i_buf1*2+1];
        end
    end
    
    // Process interrupts and generate line status with buffered inputs
    always @(*) begin
        line_status = 2'b00;
        for (i = 0; i < 4; i = i + 1) begin
            i_buf2 = i; // Buffer the loop counter
            if (device_interrupts_buf2[i_buf2]) begin
                case (device_lines[i_buf2])
                    2'b00: line_status[0] = 1'b1;
                    2'b01: line_status[1] = 1'b1;
                    2'b10: line_status[0] = 1'b1;
                    2'b11: line_status[1] = 1'b1;
                endcase
            end
        end
    end
    
    // Buffer the line_status to reduce fanout load
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            line_status_buf1 <= 2'b00;
            line_status_buf2 <= 2'b00;
        end else begin
            line_status_buf1 <= line_status;
            line_status_buf2 <= line_status;
        end
    end
    
    // Register output using a buffered version of line_status
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            irq_lines <= 2'b00;
        end else begin
            irq_lines <= line_status_buf1;
        end
    end
endmodule