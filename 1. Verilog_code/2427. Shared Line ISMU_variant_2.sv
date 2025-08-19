//SystemVerilog
module shared_line_ismu(
    input clock, resetn,
    input [3:0] device_interrupts,
    input [7:0] line_assignment, // 2-bit per device
    output reg [1:0] irq_lines
);
    // Pre-decoded line assignments
    wire [1:0] dev0_line = line_assignment[1:0];
    wire [1:0] dev1_line = line_assignment[3:2];
    wire [1:0] dev2_line = line_assignment[5:4];
    wire [1:0] dev3_line = line_assignment[7:6];
    
    // Intermediate interrupt signals per line
    reg [3:0] line0_interrupts;
    reg [3:0] line1_interrupts;
    reg [3:0] line2_interrupts;
    reg [3:0] line3_interrupts;
    
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            irq_lines <= 2'b00;
        end else begin
            // Map device interrupts to their assigned lines
            line0_interrupts[0] <= (dev0_line == 2'b00) ? device_interrupts[0] : 1'b0;
            line0_interrupts[1] <= (dev1_line == 2'b00) ? device_interrupts[1] : 1'b0;
            line0_interrupts[2] <= (dev2_line == 2'b00) ? device_interrupts[2] : 1'b0;
            line0_interrupts[3] <= (dev3_line == 2'b00) ? device_interrupts[3] : 1'b0;
            
            line1_interrupts[0] <= (dev0_line == 2'b01) ? device_interrupts[0] : 1'b0;
            line1_interrupts[1] <= (dev1_line == 2'b01) ? device_interrupts[1] : 1'b0;
            line1_interrupts[2] <= (dev2_line == 2'b01) ? device_interrupts[2] : 1'b0;
            line1_interrupts[3] <= (dev3_line == 2'b01) ? device_interrupts[3] : 1'b0;
            
            line2_interrupts[0] <= (dev0_line == 2'b10) ? device_interrupts[0] : 1'b0;
            line2_interrupts[1] <= (dev1_line == 2'b10) ? device_interrupts[1] : 1'b0;
            line2_interrupts[2] <= (dev2_line == 2'b10) ? device_interrupts[2] : 1'b0;
            line2_interrupts[3] <= (dev3_line == 2'b10) ? device_interrupts[3] : 1'b0;
            
            line3_interrupts[0] <= (dev0_line == 2'b11) ? device_interrupts[0] : 1'b0;
            line3_interrupts[1] <= (dev1_line == 2'b11) ? device_interrupts[1] : 1'b0;
            line3_interrupts[2] <= (dev2_line == 2'b11) ? device_interrupts[2] : 1'b0;
            line3_interrupts[3] <= (dev3_line == 2'b11) ? device_interrupts[3] : 1'b0;
            
            // Combine interrupts per line using reduction OR
            irq_lines[0] <= |line0_interrupts;
            irq_lines[1] <= |line1_interrupts;
        end
    end
endmodule