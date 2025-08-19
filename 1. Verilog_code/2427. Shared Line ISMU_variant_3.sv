//SystemVerilog
module shared_line_ismu(
    input clock, resetn,
    input [3:0] device_interrupts,
    input [7:0] line_assignment, // 2-bit per device
    input [1:0] irq_ack,         // Acknowledge signals from receivers
    output reg [1:0] irq_req     // Request signals to receivers
);
    reg [1:0] dev_line;
    reg [1:0] irq_pending;       // Track pending interrupt requests
    
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            irq_req <= 2'b00;
            irq_pending <= 2'b00;
        end else begin
            // Process new interrupt requests - unrolled loop
            // Device 0
            dev_line[0] = line_assignment[0];
            dev_line[1] = line_assignment[1];
            if (device_interrupts[0])
                irq_pending[dev_line] <= 1'b1;
                
            // Device 1
            dev_line[0] = line_assignment[2];
            dev_line[1] = line_assignment[3];
            if (device_interrupts[1])
                irq_pending[dev_line] <= 1'b1;
                
            // Device 2
            dev_line[0] = line_assignment[4];
            dev_line[1] = line_assignment[5];
            if (device_interrupts[2])
                irq_pending[dev_line] <= 1'b1;
                
            // Device 3
            dev_line[0] = line_assignment[6];
            dev_line[1] = line_assignment[7];
            if (device_interrupts[3])
                irq_pending[dev_line] <= 1'b1;
            
            // Handle request-acknowledge handshaking - unrolled loop
            // Line 0
            if (irq_pending[0] && !irq_req[0]) begin
                // New pending interrupt - raise request
                irq_req[0] <= 1'b1;
            end else if (irq_req[0] && irq_ack[0]) begin
                // Request acknowledged - clear request and pending status
                irq_req[0] <= 1'b0;
                irq_pending[0] <= 1'b0;
            end
            
            // Line 1
            if (irq_pending[1] && !irq_req[1]) begin
                // New pending interrupt - raise request
                irq_req[1] <= 1'b1;
            end else if (irq_req[1] && irq_ack[1]) begin
                // Request acknowledged - clear request and pending status
                irq_req[1] <= 1'b0;
                irq_pending[1] <= 1'b0;
            end
        end
    end
endmodule