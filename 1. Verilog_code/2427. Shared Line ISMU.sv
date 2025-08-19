module shared_line_ismu(
    input clock, resetn,
    input [3:0] device_interrupts,
    input [7:0] line_assignment, // 2-bit per device
    output reg [1:0] irq_lines
);
    integer i;
    reg [1:0] dev_line;
    
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            irq_lines <= 2'b00;
        end else begin
            irq_lines <= 2'b00;
            for (i = 0; i < 4; i = i + 1) begin
                dev_line[0] = line_assignment[i*2];
                dev_line[1] = line_assignment[i*2+1];
                
                if (device_interrupts[i])
                    irq_lines[dev_line] <= 1'b1;
            end
        end
    end
endmodule