module APB_IVMU (
    input pclk, preset_n,
    input [7:0] paddr,
    input psel, penable, pwrite,
    input [31:0] pwdata,
    output reg [31:0] prdata,
    input [15:0] irq_in,
    output reg [31:0] vector,
    output reg irq_out
);
    reg [31:0] regs [0:15]; // Vector table
    reg [15:0] mask;
    wire [15:0] pending;
    wire apb_write, apb_read;
    integer i;
    
    assign apb_write = psel & penable & pwrite;
    assign apb_read = psel & penable & ~pwrite;
    assign pending = irq_in & ~mask;
    
    always @(posedge pclk or negedge preset_n) begin
        if (!preset_n) begin
            for (i = 0; i < 16; i = i + 1) regs[i] <= 32'hE000_0000 + (i << 8);
            mask <= 16'hFFFF;
            irq_out <= 0;
        end else begin
            if (apb_write) begin
                if (paddr[7:4] == 0) regs[paddr[3:0]] <= pwdata;
                else if (paddr == 8'h40) mask <= pwdata[15:0];
            end
            
            if (apb_read) begin
                if (paddr[7:4] == 0) prdata <= regs[paddr[3:0]];
                else if (paddr == 8'h40) prdata <= {16'h0, mask};
                else if (paddr == 8'h44) prdata <= {16'h0, pending};
            end
            
            irq_out <= |pending;
            if (|pending) begin
                for (i = 15; i >= 0; i = i - 1)
                    if (pending[i]) vector <= regs[i[3:0]];
            end
        end
    end
endmodule