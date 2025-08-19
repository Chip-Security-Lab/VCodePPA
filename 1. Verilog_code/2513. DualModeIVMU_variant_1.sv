//SystemVerilog
`timescale 1ns/1ps
module DualModeIVMU #(
    parameter DIRECT_BASE = 32'hB000_0000,
    parameter VECTOR_BASE = 32'hB100_0000
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  interrupt,
    input  wire        mode_sel,   // 0=direct, 1=vectored
    input  wire        irq_ack,
    output reg  [31:0] isr_addr,
    output reg         irq_active
);

    reg  [7:0]  irq_status;
    wire [7:0]  new_irqs;
    reg         next_irq_active;
    reg  [31:0] next_isr_addr;
    reg  [7:0]  next_irq_status;
    integer     i;
    reg  [2:0]  highest_irq;
    reg         any_new_irq;

    assign new_irqs = interrupt & ~irq_status;

    // Parallel Prefix Adder (Kogge-Stone) for 32-bit addition
    function [31:0] kogge_stone_adder;
        input [31:0] a;
        input [31:0] b;
        input        cin;
        reg   [31:0] g [0:5];
        reg   [31:0] p [0:5];
        reg   [31:0] carry;
        integer      k;
        begin
            // Stage 0: Initial propagate and generate
            g[0] = a & b;
            p[0] = a ^ b;

            // Stage 1
            for (k = 0; k < 32; k = k + 1) begin
                if (k == 0)
                    g[1][k] = g[0][k];
                else
                    g[1][k] = g[0][k] | (p[0][k] & g[0][k-1]);
                p[1][k] = p[0][k] & p[0][k-1];
            end

            // Stage 2
            for (k = 0; k < 32; k = k + 1) begin
                if (k < 2)
                    g[2][k] = g[1][k];
                else
                    g[2][k] = g[1][k] | (p[1][k] & g[1][k-2]);
                p[2][k] = p[1][k] & p[1][k-2];
            end

            // Stage 3
            for (k = 0; k < 32; k = k + 1) begin
                if (k < 4)
                    g[3][k] = g[2][k];
                else
                    g[3][k] = g[2][k] | (p[2][k] & g[2][k-4]);
                p[3][k] = p[2][k] & p[2][k-4];
            end

            // Stage 4
            for (k = 0; k < 32; k = k + 1) begin
                if (k < 8)
                    g[4][k] = g[3][k];
                else
                    g[4][k] = g[3][k] | (p[3][k] & g[3][k-8]);
                p[4][k] = p[3][k] & p[3][k-8];
            end

            // Stage 5
            for (k = 0; k < 32; k = k + 1) begin
                if (k < 16)
                    g[5][k] = g[4][k];
                else
                    g[5][k] = g[4][k] | (p[4][k] & g[4][k-16]);
                p[5][k] = p[4][k] & p[4][k-16];
            end

            // Carry calculation
            carry[0] = cin;
            for (k = 1; k < 32; k = k + 1)
                carry[k] = g[5][k-1] | (p[5][k-1] & cin);

            // Sum calculation
            for (k = 0; k < 32; k = k + 1)
                kogge_stone_adder[k] = p[0][k] ^ carry[k];
        end
    endfunction

    // Find highest priority interrupt and calculate next_isr_addr combinationally
    always @(*) begin
        highest_irq = 3'd0;
        any_new_irq = 1'b0;
        next_isr_addr = 32'h0;
        for (i = 7; i >= 0; i = i - 1) begin
            if (new_irqs[i] && !any_new_irq) begin
                highest_irq = i[2:0];
                any_new_irq = 1'b1;
            end
        end

        if (mode_sel) begin
            if (any_new_irq)
                next_isr_addr = kogge_stone_adder(VECTOR_BASE, (highest_irq << 3), 1'b0);
            else
                next_isr_addr = isr_addr;
        end else begin
            if (any_new_irq)
                next_isr_addr = DIRECT_BASE;
            else
                next_isr_addr = isr_addr;
        end
    end

    // Compute next states for irq_status and irq_active
    always @(*) begin
        if (!rst_n) begin
            next_irq_status = 8'h0;
            next_irq_active = 1'b0;
        end else if (irq_ack) begin
            next_irq_status = irq_status;
            next_irq_active = 1'b0;
        end else if (|new_irqs && !irq_active) begin
            next_irq_status = irq_status | new_irqs;
            next_irq_active = 1'b1;
        end else begin
            next_irq_status = irq_status;
            next_irq_active = irq_active;
        end
    end

    // Registers moved behind combinational logic (retiming)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            irq_status <= 8'h0;
            irq_active <= 1'b0;
            isr_addr   <= 32'h0;
        end else begin
            irq_status <= next_irq_status;
            irq_active <= next_irq_active;
            isr_addr   <= next_isr_addr;
        end
    end

endmodule