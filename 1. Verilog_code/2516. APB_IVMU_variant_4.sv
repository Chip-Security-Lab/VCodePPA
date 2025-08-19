//SystemVerilog
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

    assign apb_write = psel & penable & pwrite;
    assign apb_read = psel & penable & ~pwrite;
    assign pending = irq_in & ~mask;

    // Always block for state updates (regs, mask)
    always @(posedge pclk or negedge preset_n) begin
        if (!preset_n) begin
            regs[0] <= 32'hE000_0000 + (0 << 8);
            regs[1] <= 32'hE000_0000 + (1 << 8);
            regs[2] <= 32'hE000_0000 + (2 << 8);
            regs[3] <= 32'hE000_0000 + (3 << 8);
            regs[4] <= 32'hE000_0000 + (4 << 8);
            regs[5] <= 32'hE000_0000 + (5 << 8);
            regs[6] <= 32'hE000_0000 + (6 << 8);
            regs[7] <= 32'hE000_0000 + (7 << 8);
            regs[8] <= 32'hE000_0000 + (8 << 8);
            regs[9] <= 32'hE000_0000 + (9 << 8);
            regs[10] <= 32'hE000_0000 + (10 << 8);
            regs[11] <= 32'hE000_0000 + (11 << 8);
            regs[12] <= 32'hE000_0000 + (12 << 8);
            regs[13] <= 32'hE000_0000 + (13 << 8);
            regs[14] <= 32'hE000_0000 + (14 << 8);
            regs[15] <= 32'hE000_0000 + (15 << 8);
            mask <= 16'hFFFF;
        end else begin
            if (apb_write) begin
                if (paddr[7:4] == 0) begin
                    regs[paddr[3:0]] <= pwdata;
                end else if (paddr == 8'h40) begin
                    mask <= pwdata[15:0];
                end
            end
        end
    end

    // Always block for APB read output (prdata)
    always @(posedge pclk or negedge preset_n) begin
        if (!preset_n) begin
            prdata <= 32'h0;
        end else begin
            if (apb_read) begin
                if (paddr[7:4] == 0) begin
                    prdata <= regs[paddr[3:0]];
                end else if (paddr == 8'h40) begin
                    prdata <= {16'h0, mask};
                end else if (paddr == 8'h44) begin
                    prdata <= {16'h0, pending};
                end else begin
                    prdata <= 32'h0; // Default value for unmapped reads
                end
            end
        end
    end

    // Always block for IRQ and Vector outputs (irq_out, vector)
    always @(posedge pclk or negedge preset_n) begin
        if (!preset_n) begin
            irq_out <= 1'b0;
            vector <= 32'h0;
        end else begin
            irq_out <= |pending;

            if (|pending) begin
                if (pending[15]) vector <= regs[15];
                else if (pending[14]) vector <= regs[14];
                else if (pending[13]) vector <= regs[13];
                else if (pending[12]) vector <= regs[12];
                else if (pending[11]) vector <= regs[11];
                else if (pending[10]) vector <= regs[10];
                else if (pending[9]) vector <= regs[9];
                else if (pending[8]) vector <= regs[8];
                else if (pending[7]) vector <= regs[7];
                else if (pending[6]) vector <= regs[6];
                else if (pending[5]) vector <= regs[5];
                else if (pending[4]) vector <= regs[4];
                else if (pending[3]) vector <= regs[3];
                else if (pending[2]) vector <= regs[2];
                else if (pending[1]) vector <= regs[1];
                else if (pending[0]) vector <= regs[0];
            end
        end
    end

endmodule