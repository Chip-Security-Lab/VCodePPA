//SystemVerilog
// Top level module with pipelined architecture
module clk_gate_async_rst #(
    parameter INIT = 0
) (
    input  wire clk,
    input  wire rst_n,
    input  wire en,
    input  wire valid_in,
    output wire q,
    output wire valid_out,
    output wire ready_in
);

    // Pipeline control signals
    wire valid_stage1, valid_stage2, valid_stage3;
    wire ready_stage1, ready_stage2, ready_stage3;
    
    // Internal data signals
    wire reset_signal_stage1, reset_signal_stage2;
    wire enable_signal_stage1, enable_signal_stage2;
    wire q_internal_stage2, q_internal_stage3;
    
    // Ready signal propagation (assuming always ready in this implementation)
    assign ready_in = 1'b1;
    assign ready_stage1 = 1'b1;
    assign ready_stage2 = 1'b1;
    assign ready_stage3 = 1'b1;
    
    // Stage 1: Reset and enable controllers
    reset_controller reset_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .rst_n_in(rst_n),
        .valid_in(valid_in),
        .valid_out(valid_stage1),
        .reset_out(reset_signal_stage1)
    );

    enable_controller en_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .enable_in(en),
        .valid_in(valid_in),
        .valid_out(),  // Connected through reset_controller
        .enable_out(enable_signal_stage1)
    );

    // Pipeline registers between stage 1 and 2
    pipeline_reg stage1_to_stage2 (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_stage1),
        .valid_out(valid_stage2),
        .reset_in(reset_signal_stage1),
        .reset_out(reset_signal_stage2),
        .enable_in(enable_signal_stage1),
        .enable_out(enable_signal_stage2)
    );

    // Stage 2: Toggle logic
    toggle_logic #(
        .INIT(INIT)
    ) toggle_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .rst_n_pipe(reset_signal_stage2),
        .en(enable_signal_stage2),
        .valid_in(valid_stage2),
        .valid_out(valid_stage3),
        .q_out(q_internal_stage2)
    );
    
    // Pipeline registers between stage 2 and 3
    pipeline_reg_q stage2_to_stage3 (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_stage3),
        .valid_out(valid_out),
        .q_in(q_internal_stage2),
        .q_out(q_internal_stage3)
    );

    // Stage 3: Output buffer
    output_buffer out_buffer (
        .clk(clk),
        .rst_n(rst_n),
        .q_in(q_internal_stage3),
        .valid_in(valid_out),
        .q_out(q)
    );

endmodule

// Pipeline register module for control signals
module pipeline_reg (
    input  wire clk,
    input  wire rst_n,
    input  wire valid_in,
    output reg  valid_out,
    input  wire reset_in,
    output reg  reset_out,
    input  wire enable_in,
    output reg  enable_out
);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
            reset_out <= 1'b0;
            enable_out <= 1'b0;
        end else begin
            valid_out <= valid_in;
            reset_out <= reset_in;
            enable_out <= enable_in;
        end
    end
endmodule

// Pipeline register module for data signals
module pipeline_reg_q (
    input  wire clk,
    input  wire rst_n,
    input  wire valid_in,
    output reg  valid_out,
    input  wire q_in,
    output reg  q_out
);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
            q_out <= 1'b0;
        end else begin
            valid_out <= valid_in;
            q_out <= q_in;
        end
    end
endmodule

// Reset controller module - Pipeline Stage 1
module reset_controller (
    input  wire clk,
    input  wire rst_n,
    input  wire rst_n_in,
    input  wire valid_in,
    output reg  valid_out,
    output reg  reset_out
);
    // Registered reset conditioning with valid signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_out <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            reset_out <= rst_n_in;
            valid_out <= valid_in;
        end
    end
endmodule

// Enable controller module - Pipeline Stage 1
module enable_controller (
    input  wire clk,
    input  wire rst_n,
    input  wire enable_in,
    input  wire valid_in,
    output reg  valid_out,
    output reg  enable_out
);
    // Registered enable conditioning with valid signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_out <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            enable_out <= enable_in;
            valid_out <= valid_in;
        end
    end
endmodule

// Toggle logic module - Pipeline Stage 2
module toggle_logic #(
    parameter INIT = 0
) (
    input  wire clk,
    input  wire rst_n,
    input  wire rst_n_pipe,
    input  wire en,
    input  wire valid_in,
    output reg  valid_out,
    output reg  q_out
);
    
    // Registered toggle logic with valid signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_out <= INIT;
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_in;
            
            if (!rst_n_pipe)
                q_out <= INIT;
            else if (en && valid_in)
                q_out <= ~q_out;
        end
    end
endmodule

// Output buffer module - Pipeline Stage 3
module output_buffer (
    input  wire clk,
    input  wire rst_n,
    input  wire q_in,
    input  wire valid_in,
    output reg  q_out
);
    // Registered output conditioning
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_out <= 1'b0;
        end else if (valid_in) begin
            q_out <= q_in;
        end
    end
endmodule